{ lib, config, pkgs, ... }:
{
  config = lib.mkIf config.machines.${config.networking.hostName}.workstation.enable {
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        runAsRoot = false;
        swtpm.enable = true;
      };
    };

    environment.systemPackages = with pkgs; [
      qemu
      virtiofsd
    ];

    users.extraGroups.libvirtd.members = [ "lennart" ];
  };
}
