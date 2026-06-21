{ lib, config, pkgs, ... }:
{
  config = lib.mkIf config.meta.self.workstation.enable {
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
