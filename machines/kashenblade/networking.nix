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
    macAddress = "96:00:03:09:09:66";
    ipAddresses = [
      "167.235.154.30/32"
      "2a01:4f8:c0c:d91f::1/64"
    ];
  };
}
