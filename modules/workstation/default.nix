# 
{ lib, ... }: {
  imports = [
    ./backup-home.nix
    ./docker.nix
    ./lennart.nix
    ./sudo.nix
    ./user-keys.nix
    ./libvirt.nix
    ./ssh-config.nix
    ./email.nix
  ];

  options.modules.workstation.enable = lib.mkOption {
    default = false;
    description = ''
      This is a machine I use interactivly regularly (laptop, desktop, etc.)
    '';
  };
}
