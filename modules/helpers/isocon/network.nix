# What the container can reach, and what can reach it. Each container gets its
# own network unit: it creates the container's user and network namespaces and
# connects them with pasta. pasta turns the guest's TCP and UDP into ordinary
# sockets of its own, so the host kernel never routes or NATs the guest's
# packets, and nothing but IPv4 TCP and UDP leaves. pasta may only open
# connections to public addresses: not to the host itself, private and VPN
# ranges, other containers, or IPv6. The host reaches the container's
# `tcpPorts` and `udpPorts` on 127.0.0.1, and nothing else.
{ config, lib, pkgs, ... }:
let
  cfg = config.isocon;
  inherit (import ./names.nix { inherit lib; }) unit networkUnit networkDir holder uidBase units networkUnits;

  forwardedPorts = ports: if ports == [ ] then "none" else "127.0.0.1/${lib.concatMapStringsSep "," toString ports}";

  # The namespaces belong to the container's host user, so that pasta and
  # runsc, as that user, can join them. A sleeping holder keeps them alive and
  # reports its PID once they exist; runsc finds them through ${holder name}.
  # pasta forks into the background once the network is up. All port
  # forwarding defaults to "auto", so each direction is set explicitly. The
  # guest's sockets are in gVisor, not in the namespace's kernel, so pasta must
  # deliver connections over the tap device instead of splicing them to the
  # namespace's loopback.
  setupNetwork = name: container: pkgs.writeShellScript "${networkUnit name}" ''
    set -eu
    exec 3< <(${pkgs.util-linux}/bin/unshare --user --net -- \
      ${pkgs.bash}/bin/sh -c 'echo $$; exec ${pkgs.coreutils}/bin/sleep infinity')
    read -r pid <&3
    ${pkgs.coreutils}/bin/ln -sfn /proc/$pid ${holder name}
    exec ${pkgs.passt}/bin/pasta --quiet --pid /run/${networkDir name}/pasta.pid \
      --userns /proc/$pid/ns/user --netns /proc/$pid/ns/net \
      --config-net --ipv4-only --ns-ifname eth0 \
      --address 10.0.2.2 --netmask 24 --gateway 10.0.2.1 --no-map-gw --dns none \
      --no-icmp --no-dhcp --no-ndp --no-dhcpv6 --no-ra --no-splice \
      --tcp-ports ${forwardedPorts container.tcpPorts} --udp-ports ${forwardedPorts container.udpPorts} \
      --tcp-ns none --udp-ns none
  '';

  # Makes the container's IDs those of uidBase (./names.nix). Mapping more than
  # one's own ID takes root.
  mapIds = name: pkgs.writeShellScript "${networkUnit name}-ids" ''
    set -eu
    echo "0 ${toString (uidBase name)} 65536" > ${holder name}/uid_map
    echo "0 ${toString (uidBase name)} 65536" > ${holder name}/gid_map
  '';
in
{
  config = lib.mkIf (cfg != { }) {
    assertions = [
      {
        # pasta runs unprivileged.
        assertion = lib.all (port: port >= 1024) (lib.concatMap (container: container.tcpPorts ++ container.udpPorts) (builtins.attrValues cfg));
        message = "isocon: forwarded ports must be 1024 or higher.";
      }
      {
        assertion = lib.allUnique (lib.concatMap (container: container.tcpPorts) (builtins.attrValues cfg));
        message = "isocon: two containers forward the same TCP port.";
      }
      {
        assertion = lib.allUnique (lib.concatMap (container: container.udpPorts) (builtins.attrValues cfg));
        message = "isocon: two containers forward the same UDP port.";
      }
      {
        # Without nftables, the rules below silently do nothing.
        assertion = config.networking.nftables.enable;
        message = "isocon needs networking.nftables.enable.";
      }
    ];

    systemd.services = lib.mkMerge [
      (units cfg (name: _: {
        bindsTo = [ "${networkUnit name}.service" ];
        after = [ "${networkUnit name}.service" ];
        # Keeps runsc itself off the host's network; the sandbox joins the
        # container's network namespace.
        serviceConfig.PrivateNetwork = true;
      }))

      (networkUnits cfg (name: container: {
        description = "Namespaces and network of isolated container ${name}";
        # Stops and restarts with the container, for fresh namespaces.
        partOf = [ "${unit name}.service" ];
        serviceConfig = {
          Type = "forking";
          PIDFile = "/run/${networkDir name}/pasta.pid";
          ExecStart = setupNetwork name container;
          ExecStartPost = "+${mapIds name}";
          RuntimeDirectory = networkDir name;
        };
      }))
    ];

    networking.nftables.tables.isocon = {
      family = "inet";
      content = ''
        set private {
          type ipv4_addr
          flags interval
          elements = { 0.0.0.0/8, 10.0.0.0/8, 100.64.0.0/10, 127.0.0.0/8, 169.254.0.0/16, 172.16.0.0/12,
                       192.0.0.0/24, 192.168.0.0/16, 198.18.0.0/15, 224.0.0.0/3 }
        }

        # The containers' host users, by UID: NixOS checks the rules at build
        # time, where user names don't resolve.
        set containers {
          typeof meta skuid
          elements = { ${lib.concatMapStringsSep ", " (name: toString (uidBase name)) (builtins.attrNames cfg)} }
        }

        chain output {
          # pasta connects from the host itself, where the NixOS firewall would
          # let it reach e.g. ssh. Replies to connections from the host (nginx)
          # are fine.
          type filter hook output priority filter; policy accept;
          meta skuid @containers ct state established,related accept
          meta skuid @containers meta nfproto ipv6 drop
          meta skuid @containers fib daddr type local drop
          meta skuid @containers ip daddr @private drop
        }
      '';
    };
  };
}
