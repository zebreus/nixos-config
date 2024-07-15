{ ... }:
{
  imports = [
    ../../modules/helpers/hetzner.nix
  ];
  networking.useDHCP = false;
  networking.useNetworkd = true;

  modules.hetzner.wan = {
    enable = true;
    macAddress = "96:00:03:27:16:ef";
    ipAddresses = [
      "49.13.8.171/32"
      "2a01:4f8:c013:29b1::1/64"
    ];
  };
}
