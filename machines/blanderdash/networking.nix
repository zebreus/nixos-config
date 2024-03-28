{ ... }:
{
  imports = [
    ../../modules/helpers/hetzner.nix
  ];
  networking.useDHCP = false;
  networking.useNetworkd = true;
  # I have to do all these steps to get dns resolution to work
  # TODO: Figure out if networkd can do this for me
  services.resolved.enable = true;
  networking.resolvconf.useLocalResolver = false;
  services.resolved.fallbackDns = [
    "9.9.9.9"
    "1.1.1.1"
  ];
  services.resolved.extraConfig = ''
    DNS=9.9.9.9
    DNSStubListener=no
  '';

  modules.hetzner.wan = {
    enable = true;
    macAddress = "96:00:03:27:16:ef";
    ipAddresses = [
      "49.13.8.171/32"
      "2a01:4f8:c013:29b1::1/64"
    ];
  };
}
