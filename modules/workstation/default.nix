# 
{ lib, ... }: {
  imports = [
    ./backup-home.nix
    ./docker.nix
    ./email.nix
    ./emulated-systems.nix
    ./lennart.nix
    ./libvirt.nix
    ./ssh-config.nix
    ./sudo.nix
    ./user-keys.nix
  ];

  options.modules.workstation.enable = lib.mkOption {
    default = false;
    description = ''
      This is a machine I use interactivly regularly (laptop, desktop, etc.)
    '';
  };
}
