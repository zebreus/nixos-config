# What runsc itself may do on the host. It needs root to build the sandbox, so
# its unit confines it and everything it starts: the gofer and the sentry also
# drop to their own, smaller privileges (see --directfs=false in ./sandbox.nix).
#
# Not set, because they break the container: RestrictSUIDSGID (the gofer creates
# the guest's setgid directories, like the journal's) and MemoryDenyWriteExecute
# (gVisor patches the guest's code to intercept its system calls).
{ config, lib, ... }:
let
  cfg = config.modules.isolatedContainers;
  inherit (import ./names.nix { inherit lib; }) units;
in
{
  config = lib.mkIf (cfg != { }) {
    systemd.services = units cfg (_: _: {
      serviceConfig = {
        CapabilityBoundingSet = [
          "CAP_SYS_ADMIN"
          "CAP_SYS_CHROOT"
          "CAP_SYS_PTRACE"
          "CAP_SYS_RESOURCE"
          "CAP_SETUID"
          "CAP_SETGID"
          "CAP_SETPCAP"
          "CAP_CHOWN"
          "CAP_DAC_OVERRIDE"
          "CAP_DAC_READ_SEARCH"
          "CAP_FOWNER"
          "CAP_FSETID"
          "CAP_KILL"
          "CAP_NET_ADMIN"
          "CAP_NET_RAW"
        ];
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
        RestrictAddressFamilies = [ "AF_UNIX" "AF_NETLINK" "AF_PACKET" "AF_INET" "AF_INET6" ];
        SystemCallArchitectures = "native";
      };
    });
  };
}
