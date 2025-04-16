{ pkgs, config, lib, ... }:
let
  new-any-nix-shell = pkgs.any-nix-shell.overrideAttrs (old: {
    version = "gitt"; # usually harmless to omit
    src = pkgs.fetchFromGitHub {
      owner = "Zebreus";
      repo = "any-nix-shell";
      rev = "f89bc7241251a5797a4bf5fb525e18b48e5743c4";
      sha256 = "sha256-Hk5rUoqqn+4M903sPwSxf+k3NNq7ZaVC2xdDIsqcGBo=";
    };
  });
in
{
  # Set zsh as the default shell
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    histSize = 50000;

    ohMyZsh = {
      enable = true;
      plugins = [
        "git"
        "history-substring-search"
        # "web-search"
        "zoxide"
      ];
      theme = "fishy";
    };
  };

  users.defaultUserShell = pkgs.zsh;
  environment.binsh = "${pkgs.zsh}/bin/zsh";

  home-manager.users = lib.mkMerge [
    {
      root = { pkgs, ... }: {
        programs.zsh = {
          enable = true;
          initExtra = ''
            any-nix-shell zsh --info-right | source /dev/stdin
          '';
        };
        home.stateVersion = "22.11";
      };

    }
    (lib.mkIf (builtins.hasAttr "lennart" config.users.users) {
      lennart = { pkgs, ... }: {
        programs.zsh = {
          enable = true;
          initExtra = ''
            any-nix-shell zsh --info-right | source /dev/stdin
          '';
        };
        home.stateVersion = "22.11";
      };
    })

    (lib.mkIf (builtins.hasAttr "lennart" config.users.users) {
      lennart = { pkgs, ... }: {
        # programs.bash.enable = true;
        programs.atuin = {
          enable = true;
          settings = {
            # Enable auto sync every 5 minutes
            auto_sync = true;
            sync_frequency = "5m";
            sync_address = "https://api.atuin.sh";
            # Enable fuzzy search
            search_mode = "fuzzy";
            # Disable syncing dotfiles, as you are already using home-manager
            dotfiles.enabled = false;
            # Load secrets from nix
            session_path = config.age.secrets."atuin_session".path;
            key_path = config.age.secrets."atuin_key".path;
          };
          flags = [ "--disable-up-arrow" ];
        };
      };
    })

  ];

  age.secrets = (lib.mkIf (builtins.hasAttr "lennart" config.users.users) {
    "atuin_key" = {
      file = ../../secrets + "/atuin_key.age";
      mode = "0444";
    };
    "atuin_session" = {
      file = ../../secrets + "/atuin_session.age";
      mode = "0444";
    };
  });


  environment.systemPackages = with pkgs; [
    new-any-nix-shell
    fzf
    zoxide
    bat
    zsh
    zsh-autosuggestions
  ];
}
