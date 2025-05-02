{ pkgs
, lib
, config
, ...
}:
let
  db_path = "/var/nix-index/current";
  mode = "755";
  user = "nix-index";
in
{
  config = lib.mkIf config.machines.${config.networking.hostName}.workstation.enable {
    users.users."${user}" = {
      isSystemUser = true;
      group = user;
    };
    users.groups."${user}" = { };

    # programs.nix-index.enable = true;
    # programs.nix-index.enableBashIntegration = true;

    nix.settings.allowed-users = [ user ];

    environment.systemPackages = with pkgs; [
      nix-index
    ];

    systemd.tmpfiles.rules = [
      "d /var/nix-index 0${mode} ${user} ${user} 14d"
    ];

    environment.sessionVariables.NIX_INDEX_DATABASE = db_path;

    systemd.services.nix-index-update = {
      description = "update nix-index database";
      after = [
        "network-online.target"
        "nix-daemon.service"
      ];
      wants = [
        "network-online.target"
        "nix-daemon.service"
      ];
      serviceConfig = {
        Type = "simple";
        Nice = 19;
        # UMask = mode;
        # DynamicUser = true;
        ReadWritePaths = "/var/nix-index/";
        CacheDirectory = "index-cache";

        User = user;
        Group = user;
      };
      environment.NIX_PATH = lib.concatStringsSep ":" config.nix.nixPath;
      script = ''
        platform="$(uname -m | sed 's/^arm64$/aarch64/')-$(uname | tr "[:upper:]" "[:lower:]")"
        path="/var/nix-index/index-$platform-$(date -I)"
        mkdir -p "$path" -m ${mode}
        XDG_CACHE_HOME=$CACHE_DIRECTORY ${lib.getExe' pkgs.nix-index "nix-index"} --show-trace -c 0 -s $platform --db "$path" || exit 1
        rm -f ${db_path}
        ln -s "$path" ${db_path}
        # && chmod ${mode} ${db_path}
        echo "link success"
      '';
      enable = true;
    };

    systemd.timers.nix-index-update = {
      description = "regularly update nix-index database";
      timerConfig.Persistent = true;
      timerConfig.OnCalendar = "Mon *-*-* 00:00:00";
      wantedBy = [
        "multi-user.target"
        "timers.target"
      ];
      enable = true;
    };
  };
}
