{ lib, ... }: {
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ../../modules
  ];

  system.stateVersion = "24.11";
  networking.hostName = "glouble";
  modules.boot.type = "secure-firstboot";
  nix.settings.max-jobs = lib.mkDefault 6;

  boot.initrd.systemd.enable = true;


  # networking.wireless.enable = false;
  # networking.networkmanager.enable = true;
  boot.supportedFilesystems.bcachefs = lib.mkForce true;
  boot.supportedFilesystems.zfs = lib.mkForce false;

  # system.nixos.variant_id = lib.mkDefault "installer";
}
