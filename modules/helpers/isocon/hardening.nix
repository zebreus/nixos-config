# What the container's processes may do on the host. runsc (./sandbox.nix) and
# pasta (./network.nix) run as the container's host user, whose IDs are the
# container's root (uidBase in ./names.nix), without any host capabilities.
# Both enter the container's user namespace, whose owner has all capabilities
# in it, but those only count for the container's own namespaces and files.
# runsc's gofer and sentry drop even those (see --directfs=false in
# ./sandbox.nix). Both units share one slice, which limits their CPU and
# memory together. The container's unit has the same limits, for the guest to
# see them.
{ config, lib, ... }:
let
  cfg = config.isocon;
  inherit (import ./names.nix { inherit lib; }) user uidBase slice units networkUnits;

  families = [ "AF_UNIX" "AF_NETLINK" "AF_INET" "AF_INET6" ];

  confined = name: {
    Slice = "${slice name}.slice";
    User = user name;
    Group = user name;
    CapabilityBoundingSet = "";
    NoNewPrivileges = true;
    ProtectSystem = "strict";
    ProtectHome = true;
    PrivateTmp = true;
    PrivateDevices = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectKernelLogs = true;
    ProtectControlGroups = true;
    ProtectClock = true;
    ProtectHostname = true;
    LockPersonality = true;
    RestrictRealtime = true;
    RestrictAddressFamilies = families;
    SystemCallArchitectures = "native";
  };

  limits = container: {
    CPUQuota = lib.mkIf (container.maxCpu != null) container.maxCpu;
    MemoryMax = lib.mkIf (container.maxMemory != null) "${toString container.maxMemory}G";
  };
in
{
  config = lib.mkIf (cfg != { }) {
    assertions = [{
      assertion = lib.allUnique (map uidBase (builtins.attrNames cfg));
      message = "isocon: two container names hash to the same host IDs; rename one.";
    }];

    users.users = lib.mapAttrs'
      (name: _: lib.nameValuePair (user name) {
        isSystemUser = true;
        uid = uidBase name;
        group = user name;
      })
      cfg;
    users.groups = lib.mapAttrs' (name: _: lib.nameValuePair (user name) { gid = uidBase name; }) cfg;

    systemd.slices = lib.mapAttrs'
      (name: container: lib.nameValuePair (slice name) {
        description = "Isolated container ${name}";
        sliceConfig = limits container;
      })
      cfg;

    systemd.services = lib.mkMerge [
      # Not set, because they break the container: RestrictSUIDSGID (the gofer
      # creates the guest's setgid directories, like the journal's) and
      # MemoryDenyWriteExecute (gVisor patches the guest's code to intercept its
      # system calls).
      (units cfg (name: container: {
        serviceConfig = confined name // limits container // {
          # AF_PACKET for the sentry's socket on the container's eth0.
          RestrictAddressFamilies = families ++ [ "AF_PACKET" ];
          # runsc puts the sandbox into a cgroup of its own below the unit's,
          # which the unit's cgroup namespace makes the root of /sys/fs/cgroup.
          # From there, runsc only sees the limits on the unit, not those on
          # the slice, and tells them to the guest.
          ProtectControlGroups = "private";
          Delegate = true;
          DelegateSubgroup = "supervisor";
          # Delegate= makes continue the default, but the sandbox never survives
          # the OOM killer. With stop, the unit's result says why it ended.
          OOMPolicy = "stop";
        };
      }))

      (networkUnits cfg (name: _: {
        serviceConfig = confined name // {
          MemoryDenyWriteExecute = true;
          RestrictSUIDSGID = true;
          # pasta's tap device.
          BindPaths = [ "/dev/net/tun" ];
          DeviceAllow = [ "/dev/net/tun rw" ];
        };
      }))
    ];
  };
}
