{ lib, ... }:
{
  networking = {
    wireless.enable = false;
    useDHCP = false;
    networkmanager.enable = true;
  };
  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
}
