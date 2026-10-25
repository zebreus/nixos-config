# Isolated containers: a NixOS system per service, booted with systemd as PID 1
# inside gVisor, a user-space kernel. A compromised service gets the sandbox,
# not the host kernel. Like `containers.<name>`, but opinionated:
#   * Filesystem: the guest's closure is bind-mounted read-only (not copied), its
#     /var is /var/lib/isolated-containers/<name> on the host, and everything
#     else is an in-memory overlay that resets on restart.
#   * Network: its own network namespace with a /30 in 10.231.0.0/16. It may open
#     connections to public IPv4 addresses only (masqueraded). The host itself,
#     private and VPN ranges, other containers and IPv6 are dropped, and nothing
#     from outside can open a connection to it. The host reaches it at `address`.
#
# Debug a running container with
#   runsc --root /run/isolated-containers/<name>/runsc exec <name> <command>
{ config, lib, pkgs, modulesPath, ... }:
let
  cfg = config.modules.isolatedContainers;
  hostStateVersion = config.system.stateVersion;

  runsc = "${pkgs.gvisor}/bin/runsc";
  ip = "${pkgs.iproute2}/bin/ip";
  sysctl = "${pkgs.procps}/bin/sysctl";
  nsenter = "${pkgs.util-linux}/bin/nsenter";

  unit = name: "isolated-container-${name}";
  runtimeDir = name: "/run/isolated-containers/${name}";
  interface = name: "ic-${name}";

  # A /30 per container from a hash of its name, so adding a container never
  # renumbers the others. Collisions are caught by an assertion.
  block = name: lib.mod (lib.fromHexString (builtins.substring 0 4 (builtins.hashString "sha256" name))) 16384;
  addressIn = name: offset: "10.231.${toString (block name / 64)}.${toString (lib.mod (block name) 64 * 4 + offset)}";

  guestDefaults = name: { lib, ... }: {
    nixpkgs.pkgs = pkgs;
    boot.isContainer = true;
    networking = {
      hostName = name;
      # eth0 is configured by the host; gVisor takes its address from there.
      useDHCP = false;
      nameservers = lib.mkDefault [ "1.1.1.1" "9.9.9.9" ];
      # gVisor has no netfilter, and the host firewall restricts the container.
      firewall.enable = false;
    };
    # No setuid binaries in the guest. gVisor also lacks the keyring calls that
    # run-wrappers.mount needs.
    security.enableWrappers = false;
    # gVisor's /proc/sys is read-only.
    systemd.suppressedSystemUnits = [ "systemd-sysctl.service" ];
    # gVisor rejects seccomp filters whose action kills the process, which is
    # what SystemCallFilter= does by default. Blocked calls fail with EPERM instead.
    systemd.packages = [
      (pkgs.writeTextDir "lib/systemd/system/service.d/gvisor-seccomp.conf" ''
        [Service]
        SystemCallErrorNumber=EPERM
      '')
    ];
    # /etc resets on every start. A stable machine ID keeps the persistent journal
    # in one directory.
    environment.etc.machine-id.text = "${builtins.substring 0 32 (builtins.hashString "sha256" name)}\n";
    # A smaller closure means fewer bind mounts.
    nix.enable = false;
    documentation.enable = false;
    system.stateVersion = lib.mkDefault hostStateVersion;
  };

  toplevel = name: container: (import "${modulesPath}/../lib/eval-config.nix" {
    system = null;
    modules = [ (guestDefaults name) container.config ];
  }).config.system.build.toplevel;

  # Everything inside the sandbox; the gVisor kernel is the boundary.
  capabilities = map (c: "CAP_${c}") [
    "CHOWN"
    "DAC_OVERRIDE"
    "DAC_READ_SEARCH"
    "FOWNER"
    "FSETID"
    "KILL"
    "SETGID"
    "SETUID"
    "SETPCAP"
    "LINUX_IMMUTABLE"
    "NET_BIND_SERVICE"
    "NET_BROADCAST"
    "NET_ADMIN"
    "NET_RAW"
    "IPC_LOCK"
    "IPC_OWNER"
    "SYS_MODULE"
    "SYS_RAWIO"
    "SYS_CHROOT"
    "SYS_PTRACE"
    "SYS_PACCT"
    "SYS_ADMIN"
    "SYS_BOOT"
    "SYS_NICE"
    "SYS_RESOURCE"
    "SYS_TIME"
    "SYS_TTY_CONFIG"
    "MKNOD"
    "LEASE"
    "AUDIT_WRITE"
    "AUDIT_CONTROL"
    "SETFCAP"
    "MAC_OVERRIDE"
    "MAC_ADMIN"
    "SYSLOG"
    "WAKE_ALARM"
    "BLOCK_SUSPEND"
    "AUDIT_READ"
  ];

  bundle = name: container: pkgs.writeTextDir "config.json" (builtins.toJSON {
    ociVersion = "1.0.0";
    process = {
      user = { uid = 0; gid = 0; };
      args = [ "${toplevel name container}/init" ];
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
      { destination = "/var"; type = "bind"; source = "/var/lib/isolated-containers/${name}"; options = [ "rbind" "rw" ]; }
    ];
    # The unit's own network namespace (PrivateNetwork=). Without a path, runsc
    # would start the sandbox in a new, empty one.
    linux.namespaces = map (type: { inherit type; }) [ "pid" "ipc" "uts" "mount" ]
      ++ [{ type = "network"; path = "/proc/self/ns/net"; }];
  });

  # runsc passes one file descriptor per OCI mount and runs out below FD 256 with
  # a whole closure. So the unit binds every store path into one directory, which
  # runsc mounts as /nix/store. Like nixos/modules/security/systemd-confinement.nix.
  storeBinds = name: container: pkgs.runCommand "${unit name}-store-binds"
    { closure = pkgs.closureInfo { rootPaths = [ (toplevel name container) ]; }; } ''
    dir=$out/lib/systemd/system/${unit name}.service.d
    mkdir -p $dir
    {
      echo '[Service]'
      while read -r path; do
        echo "BindReadOnlyPaths=$(readlink -e "$path"):${runtimeDir name}/store/$(basename "$path")"
      done < $closure/store-paths
    } > $dir/store-binds.conf
  '';

  # Runs in the unit's own network namespace (PrivateNetwork=), so the network,
  # including the host end of the veth pair, is gone when the unit stops.
  setupNetwork = name: pkgs.writeShellScript "${unit name}-network" ''
    set -eu
    host() { ${nsenter} --target 1 --net -- "$@"; }
    ${ip} link add eth0 type veth peer name ${interface name} netns 1
    host ${sysctl} -q -w net.ipv6.conf.${interface name}.disable_ipv6=1
    host ${ip} addr add ${addressIn name 1}/30 dev ${interface name}
    host ${ip} link set ${interface name} up
    ${sysctl} -q -w net.ipv6.conf.eth0.disable_ipv6=1
    ${ip} addr add ${addressIn name 2}/30 dev eth0
    ${ip} link set eth0 up
    ${ip} link set lo up
    ${ip} route add default via ${addressIn name 1}
  '';
in
{
  options.modules.isolatedContainers = lib.mkOption {
    default = { };
    description = "NixOS systems that each run in their own gVisor sandbox (see the top of this file).";
    type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
      options = {
        config = lib.mkOption {
          type = lib.types.deferredModule;
          description = "The container's NixOS configuration.";
        };
        address = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default = addressIn name 2;
          description = "The container's IPv4 address. The host can reach all of its ports.";
        };
      };
    }));
  };

  config = lib.mkMerge [
    {
      # pkgs.gvisor, updated. Unconditional, so that pkgs does not depend on cfg.
      nixpkgs.overlays = [ (final: prev: { gvisor = prev.callPackage ./gvisor.nix { inherit (prev) gvisor; }; }) ];
    }

    (lib.mkIf (cfg != { }) {
      assertions = lib.mapAttrsToList
        (name: _: {
          assertion = builtins.match "[a-z0-9-]{1,12}" name != null;
          message = "modules.isolatedContainers.${name}: names are 1 to 12 characters of a-z, 0-9 and -, because they end up in the interface name ${interface name}.";
        })
        cfg ++ [
        {
          assertion = lib.allUnique (map block (builtins.attrNames cfg));
          message = "modules.isolatedContainers: two container names hash to the same subnet; rename one.";
        }
        {
          # Provided by the overlay above, see ./gvisor.nix.
          assertion = lib.versionAtLeast pkgs.gvisor.version "20260921";
          message = "modules.isolatedContainers needs gVisor 20260921 or newer, for systemd as PID 1.";
        }
        {
          # Without nftables, the rules below silently do nothing.
          assertion = config.networking.nftables.enable;
          message = "modules.isolatedContainers needs networking.nftables.enable.";
        }
      ];

      # Keeps host users out of the containers' /var.
      systemd.tmpfiles.rules = [ "d /var/lib/isolated-containers 0700 root root -" ];

      # For the containers' internet access.
      boot.kernel.sysctl."net.ipv4.conf.all.forwarding" = lib.mkDefault true;
      networking.dhcpcd.denyInterfaces = [ "ic-*" ];

      # For the debug command at the top of this file.
      environment.systemPackages = [ pkgs.gvisor ];

      systemd.packages = lib.mapAttrsToList storeBinds cfg;

      systemd.services = lib.mapAttrs'
        (name: container: lib.nameValuePair (unit name) {
          description = "Isolated container ${name}";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          serviceConfig = {
            # The guest's /var.
            StateDirectory = "isolated-containers/${name}";
            RuntimeDirectory = "isolated-containers/${name}";
            PrivateNetwork = true;
            ExecStartPre = [
              (setupNetwork name)
              "${pkgs.coreutils}/bin/mkdir -p ${runtimeDir name}/rootfs"
            ];
            # --ignore-cgroups keeps the sandbox in this unit's cgroup, so systemd
            # accounts for and stops all of it.
            ExecStart = "${runsc} --root ${runtimeDir name}/runsc --network=sandbox --overlay2=root:memory --in-sandbox-cgroup=v2 --ignore-cgroups run --bundle ${bundle name container} ${name}";
            # SIGRTMIN+3 makes systemd in the guest shut down cleanly.
            ExecStop = "${runsc} --root ${runtimeDir name}/runsc kill ${name} 37";
            ExecStopPost = "-${runsc} --root ${runtimeDir name}/runsc delete -force ${name}";
            Restart = "on-failure";
          };
        })
        cfg;

      networking.nftables.tables.isolated-containers = {
        family = "inet";
        content = ''
          set private {
            type ipv4_addr
            flags interval
            elements = { 0.0.0.0/8, 10.0.0.0/8, 100.64.0.0/10, 127.0.0.0/8, 169.254.0.0/16, 172.16.0.0/12,
                         192.0.0.0/24, 192.168.0.0/16, 198.18.0.0/15, 224.0.0.0/3 }
          }

          chain input {
            # The NixOS firewall would let containers reach e.g. ssh on the host.
            type filter hook input priority filter - 1; policy accept;
            iifname "ic-*" ct state established,related accept
            iifname "ic-*" drop
          }

          chain forward {
            type filter hook forward priority filter - 1; policy accept;
            iifname "ic-*" ip daddr != @private accept
            iifname "ic-*" drop
            oifname "ic-*" ct state established,related accept
            oifname "ic-*" drop
          }

          chain postrouting {
            type nat hook postrouting priority srcnat; policy accept;
            iifname "ic-*" masquerade
          }
        '';
      };
    })
  ];
}
