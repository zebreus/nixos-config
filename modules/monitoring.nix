{ config, lib, ... }:
let
  thisMachine = config.machines."${config.networking.hostName}";
  # For now, we just assume that all machines with a sshPublicKey are accessible.
  accessibleMachines = lib.attrValues ((lib.filterAttrs (name: machine: machine.sshPublicKey != null)) config.machines);
in
{
  config = lib.mkIf thisMachine.monitoring.enable {
    networking.firewall = {
      allowedTCPPorts = [ 80 443 ];
    };

    security.acme = {
      acceptTerms = true;
      certs = {
        "grafana.antibuild.ing".email = "lennarteichhorn@gmail.com";
      };
    };

    services = {
      grafana = {
        enable = true;
        settings.server = {
          domain = "grafana.antibuild.ing";
          http_port = 2342;
          http_addr = "[::]";
        };
      };
      prometheus = {
        enable = true;
        scrapeConfigs = [
          {
            job_name = config.networking.hostName;
            static_configs = [
              {
                targets = (builtins.map
                  (machine: machine.name)
                  accessibleMachines);
              }
            ];
          }
        ];
      };
      nginx = {
        enable = true;
        # Only allow PFS-enabled ciphers with AES256
        recommendedTlsSettings = true;
        recommendedOptimisation = true;
        recommendedGzipSettings = true;
        recommendedProxySettings = true;
        virtualHosts = {
          "grafana.antibuild.ing" = {
            enableACME = true;
            forceSSL = true;
            locations = {
              "/" = {
                proxyPass = "http://[::1]:2342";
                proxyWebsockets = true;
              };
            };
          };
        };
      };
    };
  };
}
