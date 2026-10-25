{ ... }:
{
  networking.useDHCP = false;
  networking.useNetworkd = true;

  # Hetzner Cloud WAN interface, see
  # https://discourse.nixos.org/t/nixos-on-hetzner-cloud-servers-ipv6/221/6
  systemd.network.networks."20-wan" = {
    matchConfig.MACAddress = "96:00:03:27:16:ef";
    address = [
      "49.13.8.171/32"
      "2a01:4f8:c013:29b1::1/64"
    ];
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
}
