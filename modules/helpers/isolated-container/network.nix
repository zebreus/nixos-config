# What the container can reach, and what can reach it. Each container gets its
# own network unit, which runs as the container's own user without privileges:
# it creates the container's network namespace and connects it with pasta.
# pasta turns the guest's TCP and UDP into ordinary sockets of its own, so the
# host kernel never routes or NATs the guest's packets, and nothing but IPv4 TCP
# and UDP leaves. pasta may only open connections to public addresses: not to
# the host itself, private and VPN ranges, other containers, or IPv6. The host
# reaches the container's `ports` on 127.0.0.1, and nothing else.
{ config, lib, pkgs, ... }:
let
  cfg = config.modules.isolatedContainers;
  inherit (import ./names.nix { inherit lib; }) unit networkUnit user networkDir netns units;

  # Fixed, because the nftables rules match it and NixOS checks them at build
  # time, where group names don't resolve.
  gid = 30231;

  forwardedPorts = ports: if ports == [ ] then "none" else "127.0.0.1/${lib.concatMapStringsSep "," toString ports}";

  # The network namespace belongs to a user namespace of the container's user,
  # so that pasta, as that user, can join both. A sleeping holder keeps them
  # alive and reports its PID once they exist; runsc finds the network
  # namespace through ${netns name}. pasta forks into the background once the
  # network is up. All port forwarding defaults to "auto", so each direction is
  # set explicitly. The guest's sockets are in gVisor, not in the namespace's
  # kernel, so pasta must deliver connections over the tap device instead of
  # splicing them to the namespace's loopback.
  setupNetwork = name: container: pkgs.writeShellScript "${networkUnit name}" ''
    set -eu
    exec 3< <(${pkgs.util-linux}/bin/unshare --user --map-root-user --net -- \
      ${pkgs.bash}/bin/sh -c 'echo $$; exec ${pkgs.coreutils}/bin/sleep infinity')
    read -r holder <&3
    ${pkgs.coreutils}/bin/ln -sfn /proc/$holder/ns/net ${netns name}
    exec ${pkgs.passt}/bin/pasta --quiet --pid /run/${networkDir name}/pasta.pid \
      --userns /proc/$holder/ns/user --netns /proc/$holder/ns/net \
      --config-net --ipv4-only --ns-ifname eth0 \
      --address 10.0.2.2 --netmask 24 --gateway 10.0.2.1 --no-map-gw --dns none \
      --no-icmp --no-dhcp --no-ndp --no-dhcpv6 --no-ra --no-splice \
      --tcp-ports ${forwardedPorts container.ports} --udp-ports none --tcp-ns none --udp-ns none
  '';
in
{
  config = lib.mkIf (cfg != { }) {
    assertions = [
      {
        # pasta runs unprivileged.
        assertion = lib.all (port: port >= 1024) (lib.concatMap (container: container.ports) (builtins.attrValues cfg));
        message = "modules.isolatedContainers: forwarded ports must be 1024 or higher.";
      }
      {
        assertion = lib.allUnique (lib.concatMap (container: container.ports) (builtins.attrValues cfg));
        message = "modules.isolatedContainers: two containers forward the same port.";
      }
      {
        # Without nftables, the rules below silently do nothing.
        assertion = config.networking.nftables.enable;
        message = "modules.isolatedContainers needs networking.nftables.enable.";
      }
    ];

    users.groups.isolated-containers.gid = gid;
    users.users = lib.mapAttrs'
      (name: _: lib.nameValuePair (user name) {
        isSystemUser = true;
        group = "isolated-containers";
      })
      cfg;

    systemd.services = lib.mkMerge [
      (units cfg (name: _: {
        bindsTo = [ "${networkUnit name}.service" ];
        after = [ "${networkUnit name}.service" ];
        # Keeps runsc itself off the host's network; the sandbox joins the
        # container's network namespace.
        serviceConfig.PrivateNetwork = true;
      }))

      (lib.mapAttrs'
        (name: container: lib.nameValuePair (networkUnit name) {
          description = "Network of isolated container ${name}";
          # Stops and restarts with the container, for a fresh namespace.
          partOf = [ "${unit name}.service" ];
          serviceConfig = {
            Type = "forking";
            PIDFile = "/run/${networkDir name}/pasta.pid";
            ExecStart = setupNetwork name container;
            User = user name;
            Group = "isolated-containers";
            RuntimeDirectory = networkDir name;

            # Runs without any capabilities. Its user namespace gives it the
            # ones it needs, but only for the container's namespaces.
            CapabilityBoundingSet = "";
            NoNewPrivileges = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            PrivateDevices = true;
            # pasta's tap device.
            BindPaths = [ "/dev/net/tun" ];
            DeviceAllow = [ "/dev/net/tun rw" ];
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectKernelLogs = true;
            ProtectControlGroups = true;
            ProtectClock = true;
            ProtectHostname = true;
            LockPersonality = true;
            MemoryDenyWriteExecute = true;
            RestrictRealtime = true;
            RestrictSUIDSGID = true;
            RestrictAddressFamilies = [ "AF_UNIX" "AF_NETLINK" "AF_INET" "AF_INET6" ];
            SystemCallArchitectures = "native";
          };
        })
        cfg)
    ];

    networking.nftables.tables.isolated-containers = {
      family = "inet";
      content = ''
        set private {
          type ipv4_addr
          flags interval
          elements = { 0.0.0.0/8, 10.0.0.0/8, 100.64.0.0/10, 127.0.0.0/8, 169.254.0.0/16, 172.16.0.0/12,
                       192.0.0.0/24, 192.168.0.0/16, 198.18.0.0/15, 224.0.0.0/3 }
        }

        chain output {
          # pasta connects from the host itself, where the NixOS firewall would
          # let it reach e.g. ssh. Replies to connections from the host (nginx)
          # are fine.
          type filter hook output priority filter; policy accept;
          meta skgid ${toString gid} ct state established,related accept
          meta skgid ${toString gid} meta nfproto ipv6 drop
          meta skgid ${toString gid} fib daddr type local drop
          meta skgid ${toString gid} ip daddr @private drop
        }
      '';
    };
  };
}
