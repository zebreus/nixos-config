# What the container's processes may do on the host. runsc (./sandbox.nix) and
# pasta (./network.nix) run as the container's host user, whose IDs are the
# container's root (uidBase in ./names.nix), without any host capabilities.
# Both enter the container's user namespace, whose owner has all capabilities
# in it, but those only count for the container's own namespaces and files.
# runsc's gofer and sentry drop even those (see --directfs=false in
# ./sandbox.nix). Both units share one slice, which limits their CPU and
# memory together.
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
        sliceConfig = {
          CPUQuota = lib.mkIf (container.maxCpu != null) container.maxCpu;
          MemoryMax = lib.mkIf (container.maxMemory != null) container.maxMemory;
        };
      })
      cfg;

    systemd.services = lib.mkMerge [
      # Not set, because they break the container: RestrictSUIDSGID (the gofer
      # creates the guest's setgid directories, like the journal's) and
      # MemoryDenyWriteExecute (gVisor patches the guest's code to intercept its
      # system calls).
      (units cfg (name: _: {
        # AF_PACKET for the sentry's socket on the container's eth0.
        serviceConfig = confined name // { RestrictAddressFamilies = families ++ [ "AF_PACKET" ]; };
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
