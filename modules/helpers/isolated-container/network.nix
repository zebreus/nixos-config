# What the container can reach, and what can reach it. Each container gets its
# own network namespace with a /30 in 10.231.0.0/16. It may open connections to
# public IPv4 addresses only (masqueraded). The host itself, private and VPN
# ranges, other containers and IPv6 are dropped, and nothing from outside can
# open a connection to it. The host reaches it at `address`.
{ config, lib, pkgs, ... }:
let
  cfg = config.modules.isolatedContainers;
  inherit (import ./names.nix { inherit lib; }) unit interface subnet units;

  ip = "${pkgs.iproute2}/bin/ip";

  # Runs in the unit's own network namespace (PrivateNetwork=), so the network,
  # including the host end of the veth pair, is gone when the unit stops.
  setupNetwork = name: container: pkgs.writeShellScript "${unit name}-network" ''
    set -eu
    host() { ${pkgs.util-linux}/bin/nsenter --target 1 --net -- "$@"; }
    ${ip} link add eth0 type veth peer name ${interface name} netns 1
    host ${ip} addr add ${subnet cfg name}.1/30 dev ${interface name}
    host ${ip} link set ${interface name} up
    ${ip} addr add ${container.address}/30 dev eth0
    ${ip} link set eth0 up
    ${ip} route add default via ${subnet cfg name}.1
  '';
in
{
  config = lib.mkIf (cfg != { }) {
    # Without nftables, the rules below silently do nothing.
    assertions = [{
      assertion = config.networking.nftables.enable;
      message = "modules.isolatedContainers needs networking.nftables.enable.";
    }];

    # For the containers' internet access.
    boot.kernel.sysctl."net.ipv4.conf.all.forwarding" = lib.mkDefault true;

    systemd.services = units cfg (name: container: {
      serviceConfig = {
        PrivateNetwork = true;
        ExecStartPre = [ (setupNetwork name container) ];
      };
    });

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
  };
}
