{ pkgs, ... }:
{
  # Enable docker
  virtualisation.docker = {
    enableOnBoot = true;
    enable = true;
    enableNvidia = true;
  };

  environment.systemPackages = with pkgs;
    [
      docker
      docker-compose
    ];
}
