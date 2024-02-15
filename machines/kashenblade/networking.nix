{ ... }:
{
  imports = [
    ../../common/hetzner.nix
  ];

  networking.useDHCP = false;
  networking.useNetworkd = true;

  modules.hetzner.wan = {
    enable = true;
    macAddress = "96:00:02:da:0e:63";
    ipAddresses = [
      "65.109.236.106/32"
      "2a01:4f9:c010:9ee1::1/64"
    ];
  };
}
