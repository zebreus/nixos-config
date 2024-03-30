{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    (pkgs.writeScriptBin "git-unfuck" ''
      #!/usr/bin/env bash

      git commit --amend --no-edit && git push -f
      echo unfucked!!!
    '')
  ];

  programs.git = {
    enable = true;
    lfs.enable = true;
    config = {
      user = {
        name = "Zebreus";
        email = "lennarteichhorn@googlemail.com";
      };
      init.defaultBranch = "main";
    };
  };
}
