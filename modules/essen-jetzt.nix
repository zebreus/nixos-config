{ config, lib, pkgs, ... }:
let
  cfg = config.machines.${config.networking.hostName}.essenJetztServer;

  essenjetzt = pkgs.writeShellApplication
    {
      name = "essenjetzt";

      runtimeInputs = [ pkgs.deno ];

      text = ''
        deno run --allow-net --allow-env=PORT ${../resources/essenjetzt.ts}
      '';
    };
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ essenjetzt ];
    users.users.essenjetzt = {
      isSystemUser = true;
      createHome = true;
      # Home is required for the deno cache
      home = "/var/lib/essenjetzt";
      group = "essenjetzt";
    };
    users.groups.essenjetzt = { };

    systemd.services."essenjetzt" = {
      serviceConfig = {
        Type = "simple";
        User = "essenjetzt";
        Group = "essenjetzt";
        Restart = "on-failure";
        RestartSec = "30s";
        ExecStart = "${lib.getExe essenjetzt}";
      };
      wantedBy = [ "multi-user.target" ];

      description = "essen.jetzt";

      environment = {
        PORT = "13946";
      };

      documentation = [
        "https://github.com/zebreus/nixos-config/blob/main/resources/essenjetzt.ts"
      ];
    };

    networking.firewall = {
      allowedTCPPorts = [ 80 443 ];
    };

    # Get certs
    security.acme = {
      acceptTerms = true;
      certs = {
        "essen.jetzt".email = "lennart@zebre.us";
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
      commonHttpConfig = ''
        limit_req_zone $binary_remote_addr zone=mylimit:10m rate=6r/m;
      '';
      virtualHosts = {
        "essen.jetzt" = {
          enableACME = true;
          forceSSL = true;
          locations = {
            "/" = {
              proxyPass = "http://[::1]:13946";
              extraConfig = ''
                proxy_cache_key $scheme://$host$uri$is_args$query_string;
                proxy_cache_valid 200 10m;
                limit_req zone=mylimit burst=10;
              '';
            };
          };
        };
        "man.rudelb.link" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            extraConfig = ''
              return 307 https://md.darmstadt.ccc.de/rudelblinken-38c3;
            '';
          };
        };
      };
    };
  };
}
