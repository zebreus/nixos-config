{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
  ];

  programs.git = {
    enable = true;
    lfs.enable = true;
    config.user = {
      name = "Zebreus";
      email = "lennarteichhorn@googlemail.com";
    };
  };
}
