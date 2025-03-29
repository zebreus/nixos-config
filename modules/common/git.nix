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
        deltaCacheSize = "1024m";
        packSizeLimit = "1024m";
        windowMemory = "1024m";
      };
      column = {
        ui = "auto";
      };
      branch = {
        sort = "-committerdate";
      };
      tag = {
        sort = "version:refname";
      };
      diff = {
        algorithm = "histogram";
        colorMoved = "plain";
        mnemonicPrefix = "true";
        renames = "true";
      };
      push = {
        default = "simple";
        autoSetupRemote = "true";
        followTags = "true";
      };
      fetch = {
        prune = "true";
        pruneTags = "true";
        all = "true";
      };
      help = {
        autocorrect = "prompt";
      };
      commit = {
        verbose = "true";
      };
      rerere = {
        enabled = "true";
        autoupdate = "true";
      };
      rebase = {
        updateRefs = "true";
      };


    };
  };
}
