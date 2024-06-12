{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    (pkgs.writeScriptBin "git-unfuck" ''
      #!/usr/bin/env bash

      git commit --amend --no-edit && git push --force-with-lease --force-if-includes
      echo unfucked!!!
    '')
  ];

  programs.git = {
    enable = true;
    lfs.enable = true;
    config = {
      user = {
        name = "Zebreus";
        email = "zebreus@zebre.us";
      };
      init.defaultBranch = "main";
      # I had previously increased these limits in my user config, but cannot remember why.
      # I probably had some reason to do that, so I will replicate it here
      core = {
        packedGitLimit = "1024m";
        packedGitWindowSize = "1024m";
        compression = "1";
      };
      pack = {
        deltaCacheSize = "2048m";
        packSizeLimit = "2048m";
        windowMemory = "2048m";
      };
    };
  };
}
