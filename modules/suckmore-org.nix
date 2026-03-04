{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.services.suckmore;

  suckmore = pkgs.writeShellApplication {
    name = "suckmore";

    runtimeInputs = [ pkgs.deno ];

    text = ''
      deno run --allow-net --allow-env=PORT ${../resources/suckmore.ts}
    '';
  };
in
{

  options = {
    services.suckmore = {
      enable = lib.mkEnableOption "Enable the suckmore.org server";
      baseDomain = lib.mkOption {
        type = lib.types.str;
        description = "Base domain for the suckmore.org server";
        default = "suckmore.org";
      };
      email = lib.mkOption {
        type = lib.types.str;
        description = "Email for ACME certs";
      };
      enableCaching = lib.mkEnableOption "Enable caching requests aggressively";
      port = lib.mkOption {
        type = lib.types.str;
        description = "Local port the service runs over";
        default = "12482";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ suckmore ];
    users.users.suckmore = {
      isSystemUser = true;
      createHome = true;
      # Home is required for the deno cache
      home = "/var/lib/suckmore";
      group = "suckmore";
    };
    users.groups.suckmore = { };

    systemd.services."suckmore" = {
      serviceConfig = {
        Type = "simple";
        User = "suckmore";
        Group = "suckmore";
        Restart = "on-failure";
        RestartSec = "30s";
        ExecStart = "${lib.getExe suckmore}";
      };
      wantedBy = [ "multi-user.target" ];

      description = "suckmore.org server";

      environment = {
        PORT = cfg.port;
      };
    };

    networking.firewall = {
      allowedTCPPorts = [
        80
        443
      ];
    };

    security.acme = {
      acceptTerms = true;
      defaults.webroot = "/var/lib/acme/acme-challenge/";
      certs = {
        "suckmore.org".email = cfg.email;
        "suckmore.org".group = "nginx";
        # "suckmore-wildcard" = {
        #   email = cfg.email;
        #   group = "nginx";
        #   domain = "*.suckmore.org";
        # };
      };
    };

    services.nginx = {
      enable = true;
      # Only allow PFS-enabled ciphers with AES256
      sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;
      commonHttpConfig = lib.mkIf cfg.enableCaching ''
        limit_req_zone $binary_remote_addr zone=mylimit2:10m rate=600r/m;
      '';
      virtualHosts = {
        "${cfg.baseDomain}" = {
          # enableACME = true;
          useACMEHost = "suckmore.org";
          forceSSL = true;
          locations = {
            "/" = {
              proxyPass = "http://[::1]:" + cfg.port;
              extraConfig = lib.mkIf cfg.enableCaching ''
                proxy_cache_key $scheme://$host$uri$is_args$query_string;
                proxy_cache_valid 200 10m;
                limit_req zone=mylimit2 burst=10;
              '';
            };
            "/.well-known/".root = "/var/lib/acme/acme-challenge/";
          };
        };
        # "*.${cfg.baseDomain}" = {
        #   # enableACME = true;
        #   useACMEHost = "suckmore.org";
        #   forceSSL = true;
        #   locations = {
        #     "/" = {
        #       proxyPass = "http://[::1]:" + cfg.port;
        #       extraConfig = lib.mkIf cfg.enableCaching ''
        #         proxy_cache_key $scheme://$host$uri$is_args$query_string;
        #         proxy_cache_valid 200 10m;
        #         limit_req zone=mylimit burst=10;
        #       '';
        #     };
        #   };
        # };
      };
    };
  };
}
