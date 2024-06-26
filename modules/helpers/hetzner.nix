# Copied from https://discourse.nixos.org/t/nixos-on-hetzner-cloud-servers-ipv6/221/6

{ lib, config, ... }:
with lib;
let
  cfg = config.modules.hetzner.wan;
in
{
  options.modules.hetzner.wan = {
    enable = mkEnableOption "Enable Hetzner Cloud WAN interface configuration";

    macAddress = mkOption {
      type = types.str;
      description = "MAC Address of the WAN interface";
    };

    ipAddresses = mkOption {
      type = types.listOf types.str;
      description = "List of IP Addresses on the WAN interface";
    };
  };

  config = mkIf cfg.enable {
    systemd.network.networks."20-wan" = {
      matchConfig = {
        MACAddress = cfg.macAddress;
      };
      address = cfg.ipAddresses;
      routes = [
        { Gateway = "fe80::1"; }
        { Destination = "172.31.1.1"; }
        { Gateway = "172.31.1.1"; GatewayOnLink = true; }
        { Destination = "172.16.0.0/12"; Type = "unreachable"; }
        { Destination = "192.168.0.0/16"; Type = "unreachable"; }
        { Destination = "10.0.0.0/8"; Type = "unreachable"; }
        { Destination = "fc00::/7"; Type = "unreachable"; }
      ];
    };
  };
}
