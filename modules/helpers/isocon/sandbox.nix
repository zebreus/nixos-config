# What the sandbox can see, and how runsc runs it. The guest's closure is
# bind-mounted read-only (not copied), the directories it persists are in
# /var/lib/isocon/<name> on the host, and everything else is an in-memory
# overlay that resets on restart.
{ config, lib, pkgs, ... }:
let
  cfg = config.isocon;
  inherit (import ./names.nix { inherit lib; }) unit runtimeDir holder units;

  # runsc runs as the container's root, in its user namespace (./network.nix,
  # ./hardening.nix).
  runsc = name: "${pkgs.util-linux}/bin/nsenter --user=${holder name}/ns/user -- ${pkgs.gvisor}/bin/runsc --root ${runtimeDir name}/runsc";

  # Always the users' and groups' IDs, which the owners of persisted files
  # depend on, and the journal, which would otherwise fill the memory. Sorted,
  # so that a directory is mounted before the ones inside it.
  persisted = container: lib.sort lib.lessThan (lib.unique ([ "/var/lib/nixos" "/var/log/journal" ] ++ container.persist));
  stateDir = name: "/var/lib/isocon/${name}";

  # What systemd and its services in the guest need, as each capability opens
  # more of the gVisor kernel to the guest. Notably missing are NET_RAW (no raw
  # sockets) and SYS_BOOT: without it, gVisor's reboot() fails with EPERM, so
  # systemd-shutdown exits the container at the end of a shutdown. With it,
  # reboot() fails with ENOSYS and systemd-shutdown freezes.
  capabilities = map (c: "CAP_${c}") [
    "AUDIT_WRITE"
    "CHOWN"
    "DAC_OVERRIDE"
    "DAC_READ_SEARCH"
    "FOWNER"
    "FSETID"
    "IPC_LOCK"
    "KILL"
    "MKNOD"
    "NET_BIND_SERVICE"
    # PrivateUsers= in units: mapping root into a user namespace needs it.
    "SETFCAP"
    "SETGID"
    "SETPCAP"
    "SETUID"
    "SYS_ADMIN"
    "SYS_CHROOT"
    "SYS_NICE"
    "SYS_RESOURCE"
  ];

  bundle = name: container: pkgs.writeTextDir "config.json" (builtins.toJSON {
    ociVersion = "1.0.0";
    process = {
      user = { uid = 0; gid = 0; };
      args = [ "${container.toplevel}/init" ];
      env = [ "PATH=/run/current-system/sw/bin" "container=gvisor" ];
      cwd = "/";
      capabilities = lib.genAttrs [ "bounding" "effective" "inheritable" "permitted" ] (_: capabilities);
    };
    root.path = "${runtimeDir name}/rootfs";
    hostname = name;
    mounts = [
      { destination = "/proc"; type = "proc"; source = "proc"; }
      { destination = "/dev"; type = "tmpfs"; source = "tmpfs"; }
      { destination = "/sys"; type = "sysfs"; source = "sysfs"; options = [ "ro" "nosuid" "noexec" "nodev" ]; }
      # Mounted here so that neither stage 2 nor systemd mounts these with
      # options gVisor rejects (tmpfs size=N%, cgroup2 memory_recursiveprot).
      { destination = "/sys/fs/cgroup"; type = "cgroup"; source = "cgroup"; options = [ "nosuid" "noexec" "nodev" ]; }
      { destination = "/run"; type = "tmpfs"; source = "tmpfs"; options = [ "nosuid" "nodev" "mode=755" ]; }
      { destination = "/dev/shm"; type = "tmpfs"; source = "tmpfs"; options = [ "nosuid" "nodev" "mode=1777" ]; }
      { destination = "/nix/store"; type = "bind"; source = "${runtimeDir name}/store"; options = [ "rbind" "ro" ]; }
    ] ++ map (path: { destination = path; type = "bind"; source = "${stateDir name}${path}"; options = [ "rbind" "rw" ]; }) (persisted container);
    # The container's network namespace, set up by ./network.nix.
    linux.namespaces = map (type: { inherit type; }) [ "pid" "ipc" "uts" "mount" ]
      ++ [{ type = "network"; path = "${holder name}/ns/net"; }];
  });

  # runsc passes one file descriptor per OCI mount and runs out below FD 256 with
  # a whole closure. So the unit binds every store path into one directory, which
  # runsc mounts as /nix/store. Like nixos/modules/security/systemd-confinement.nix.
  storeBinds = name: container: pkgs.runCommand "${unit name}-store-binds"
    { closure = pkgs.closureInfo { rootPaths = [ container.toplevel ]; }; } ''
    dir=$out/lib/systemd/system/${unit name}.service.d
    mkdir -p $dir
    {
      echo '[Service]'
      while read -r path; do
        echo "BindReadOnlyPaths=$path:${runtimeDir name}/store/$(basename "$path")"
      done < $closure/store-paths
    } > $dir/store-binds.conf
  '';
in
{
  config = lib.mkMerge [
    {
      # pkgs.gvisor, updated. Unconditional, so that pkgs does not depend on cfg.
      nixpkgs.overlays = [ (final: prev: { gvisor = prev.callPackage ./gvisor.nix { inherit (prev) gvisor; }; }) ];
    }

    (lib.mkIf (cfg != { }) {
      assertions = [{
        # Provided by the overlay above, see ./gvisor.nix.
        assertion = lib.versionAtLeast pkgs.gvisor.version "20260921";
        message = "isocon needs gVisor 20260921 or newer, for systemd as PID 1.";
      }];

      # For the debug command at the top of ./default.nix.
      environment.systemPackages = [ pkgs.gvisor ];

      systemd.packages = lib.mapAttrsToList storeBinds cfg;

      systemd.services = units cfg (name: container: {
        serviceConfig = {
          RuntimeDirectory = [ "isocon/${name}" "isocon/${name}/rootfs" ];
          # Owned by the container's root, and closed to host users.
          StateDirectory = "isocon/${name}";
          StateDirectoryMode = "0700";
          # The persisted directories, which runsc needs to exist. Not with
          # StateDirectory=: it would chown them back once a guest service
          # owns one.
          ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${lib.concatMapStringsSep " " (path: "${stateDir name}${path}") (persisted container)}";
          # --ignore-cgroups keeps the sandbox in this unit's cgroup, so systemd
          # accounts for and stops all of it. --directfs=false leaves all host
          # file access to the gofer, so the sentry runs as the container's
          # nobody without capabilities and gets a narrower seccomp filter.
          ExecStart = "${runsc name} --network=sandbox --overlay2=root:memory --in-sandbox-cgroup=v2 --ignore-cgroups --directfs=false run --bundle ${bundle name container} ${name}";
          # SIGRTMIN+3 makes systemd in the guest shut down cleanly. runsc kill
          # only knows the standard signals, so send it from inside the guest.
          # Then wait, as systemd kills what is left as soon as ExecStop= returns.
          # The wait fails if the guest is already gone, which is fine.
          ExecStop = [
            "${runsc name} exec ${name} /run/current-system/sw/bin/kill -s RTMIN+3 1"
            "-${runsc name} wait ${name}"
          ];
          ExecStopPost = "-${runsc name} delete -force ${name}";
        };
      });
    })
  ];
}
