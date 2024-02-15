{ lib, pkgs, config, ... }:
with lib;
{
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
}
