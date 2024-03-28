{ lib, pkgs, config, ... }: with lib; {
  config = lib.mkIf config.modules.workstation.enable {
    virtualisation.docker = lib.mkMerge [
      {
        enableOnBoot = true;
        enable = true;
      }

      # Enable nvidia if the nvidia driver is enabled
      (lib.mkIf
        (elem "nvidia" config.services.xserver.videoDrivers)
        {
          enableNvidia = true;
        })
    ];

    environment.systemPackages = with pkgs;
      [
        docker
        docker-compose
      ];

    users.extraGroups.docker.members = [ "lennart" ];
  };
}
