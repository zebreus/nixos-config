{ ... }:
{
  imports = [
    ../../modules/helpers/hetzner.nix
  ];

  networking.useDHCP = false;
  networking.useNetworkd = true;

  modules.hetzner.wan = {
    enable = true;
    macAddress = "96:00:03:09:09:66";
    ipAddresses = [
      "167.235.154.30/32"
      "2a01:4f8:c0c:d91f::1/64"
    ];
  };
}
