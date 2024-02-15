{ ... }:
{
  imports = [
    ../../modules/hetzner.nix
  ];

  networking.useDHCP = false;
  networking.useNetworkd = true;

  modules.hetzner.wan = {
    enable = true;
    macAddress = "96:00:03:05:c8:32";
    ipAddresses = [
      "37.27.11.229/32"
      "2a01:4f9:c012:cc66::1/64"
    ];
  };
}
