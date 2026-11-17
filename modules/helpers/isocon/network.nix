# What the container can reach, and what can reach it. Each container gets its
# own network unit: it creates the container's user and network namespaces and
# connects them with pasta. pasta turns the guest's TCP and UDP into ordinary
# sockets of its own, so the host kernel never routes or NATs the guest's
# packets, and nothing but TCP, UDP and ping leaves, from the host's addresses.
# pasta may only open connections to public addresses: not to the host itself,
# private, link-local and VPN ranges, or other containers. The host forwards the
# container's `tcpPorts` and `udpPorts` on 127.0.0.1, or with mode global on all
# of its addresses, and nothing else.
{ config, lib, pkgs, ... }:
let
  cfg = config.isocon;
  inherit (import ./names.nix { inherit lib; }) unit networkUnit networkDir holder uidBase units networkUnits;

  # pasta runs unprivileged in the container's user namespace, so it can't bind
  # ports below 1024. It listens on 30000 + port for them instead, and the
  # nftables rules below redirect the port there.
  pastaPort = port: if port < 1024 then 30000 + port else port;

  # pasta's options for the container's ports of one protocol.
  forwardedPorts = protocol: ports:
    if ports == [ ] then "--${protocol}-ports none"
    else lib.concatMapStringsSep " " ({ port, mode, ... }: "--${protocol}-ports ${lib.optionalString (mode == "local") "127.0.0.1/"}${toString (pastaPort port)}:${toString port}") ports;

  # The ports below 1024 of all containers, with their protocol.
  lowPorts = lib.filter ({ port, ... }: port < 1024) (lib.concatMap
    (container: map (p: p // { protocol = "tcp"; }) container.tcpPorts ++ map (p: p // { protocol = "udp"; }) container.udpPorts)
    (builtins.attrValues cfg));
  redirect = { protocol, port, ... }: "${protocol} dport ${toString port} redirect to :${toString (pastaPort port)}";

  passt = pkgs.callPackage ./passt.nix { };

  # The namespaces belong to the container's host user, so that pasta and
  # runsc, as that user, can join them. A sleeping holder keeps them alive and
  # reports its PID once they exist; runsc finds them through ${holder name}.
  # pasta forks into the background once the network is up. All port
  # forwarding defaults to "auto", so each direction is set explicitly. ICMP
  # stays on, as without it pasta also ignores NDP, which the guest needs to
  # reach its IPv6 gateway. The guest's sockets are in gVisor, not in the
  # namespace's kernel, so pasta must deliver connections over the tap device
  # instead of splicing them to the namespace's loopback.
  setupNetwork = name: container: pkgs.writeShellScript "${networkUnit name}" ''
    set -eu
    exec 3< <(${pkgs.util-linux}/bin/unshare --user --net -- \
      ${pkgs.bash}/bin/sh -c 'echo $$; exec ${pkgs.coreutils}/bin/sleep infinity')
    read -r pid <&3
    ${pkgs.coreutils}/bin/ln -sfn /proc/$pid ${holder name}
    exec ${passt}/bin/pasta --quiet --pid /run/${networkDir name}/pasta.pid \
      --userns /proc/$pid/ns/user --netns /proc/$pid/ns/net \
      --config-net --ns-ifname eth0 \
      --address 10.0.2.2 --netmask 24 --gateway 10.0.2.1 \
      --address fd00::2 --gateway fd00::1 --no-map-gw --dns none \
      --no-dhcp --no-dhcpv6 --no-ra --no-splice \
      ${forwardedPorts "tcp" container.tcpPorts} ${forwardedPorts "udp" container.udpPorts} \
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
        assertion = lib.allUnique (lib.concatMap (container: map ({ port, ... }: pastaPort port) container.tcpPorts) (builtins.attrValues cfg));
        message = "isocon: the same TCP port is forwarded twice (ports below 1024 also take 30000 + port).";
      }
      {
        assertion = lib.allUnique (lib.concatMap (container: map ({ port, ... }: pastaPort port) container.udpPorts) (builtins.attrValues cfg));
        message = "isocon: the same UDP port is forwarded twice (ports below 1024 also take 30000 + port).";
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
        set private4 {
          type ipv4_addr
          flags interval
          elements = { 0.0.0.0/8, 10.0.0.0/8, 100.64.0.0/10, 127.0.0.0/8, 169.254.0.0/16, 172.16.0.0/12,
                       192.0.0.0/24, 192.168.0.0/16, 198.18.0.0/15, 224.0.0.0/3 }
        }

        set private6 {
          type ipv6_addr
          flags interval
          elements = { ::/127, 64:ff9b:1::/48, 100::/64, 2001::/23, 2002::/16, fc00::/7, fe80::/10, ff00::/8 }
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
          meta skuid @containers fib daddr type local drop
          meta skuid @containers ip daddr @private4 drop
          meta skuid @containers ip6 daddr @private6 drop
        }

        # Ports below 1024 to pasta's ports for them: global ones from other
        # machines, and all from the host itself.
        chain redirect-in {
          type nat hook prerouting priority dstnat; policy accept;
          ${lib.concatMapStrings (p: "fib daddr type local ${redirect p}\n") (lib.filter ({ mode, ... }: mode == "global") lowPorts)}
        }

        chain redirect-out {
          type nat hook output priority dstnat; policy accept;
          ${lib.concatMapStrings (p: "${if p.mode == "global" then "fib daddr type local" else "ip daddr 127.0.0.1"} ${redirect p}\n") lowPorts}
        }
      '';
    };
  };
}
