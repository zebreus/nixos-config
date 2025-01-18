{ config, lib, pkgs, ... }:
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
        settings = {
          server = {
            domain = "grafana.antibuild.ing";
            http_port = 2342;
            http_addr = "::1";
          };
          "auth.anonymous" = {
            enabled = true;
            org_name = "Main Org.";
            org_role = "Viewer";
          };
          analytics.reporting_enabled = false;
          smtp = {
            enable = true;
            enabled = true;
            user = "root@${config.networking.hostName}.antibuild.ing";
            startTLS_policy = "MandatoryStartTLS";
            password = "$__file{${config.age.secrets."${config.networking.hostName}_mail_password".path}}";
            host = "mail.zebre.us:465";
            from_name = "Antibuilding Grafana";
            from_address = config.services.grafana.settings.smtp.user;
          };
          # security = {
          #   admin_password = "adminadmin";
          #   admin_user = "admin";
          #   admin_email = "admin@admin";
          # };
        };


        declarativePlugins = with pkgs.grafanaPlugins; [
          grafana-github-datasource
          grafana-clock-panel
          grafana-oncall-app
          grafana-piechart-panel
        ];
        provision = {
          enable = true;
          datasources.settings.datasources = [
            {
              type = "prometheus";
              isDefault = true;
              name = "prometheus";
              url = "http://localhost:${toString config.services.prometheus.port}";
              uid = "e68e5107-0b44-4438-0000-019649e85d2b";
            }
          ];
          dashboards = {
            settings = {
              providers = [
                {
                  name = "My Dashboards";
                  options.path = "/etc/grafana-dashboards";
                }
              ];
            };
          };
          alerting.contactPoints.settings = {
            contactPoints = [{
              name = "grafana-default-email";
              receivers = [{
                uid = "zebreus-email";
                type = "email";
                settings.addresses = "zebreus@zebre.us";
              }];
            }];
          };
        };
      };

      prometheus = {
        enable = true;
        scrapeConfigs = [
          {
            job_name = "node";
            static_configs = [
              {
                targets = (builtins.concatMap
                  # (machine: "${machine.name}:9100")
                  (machine: [
                    "[${config.antibuilding.ipv6Prefix}::${builtins.toString machine.address}]:${builtins.toString config.services.prometheus.exporters.node.port}"
                  ])
                  accessibleMachines);
              }
            ];
          }
          {
            job_name = "bird";
            static_configs = [
              {
                targets = (builtins.concatMap
                  # (machine: "${machine.name}:9100")
                  (machine: [
                    "[${config.antibuilding.ipv6Prefix}::${builtins.toString machine.address}]:${builtins.toString config.services.prometheus.exporters.bird.port}"
                  ])
                  accessibleMachines);
              }
            ];
          }
          {
            job_name = "mailservers";
            static_configs = [
              {
                targets = (builtins.concatMap
                  (machine: [
                    "[${config.antibuilding.ipv6Prefix}::${builtins.toString machine.address}]:${builtins.toString 9256}" # rspamd
                    "[${config.antibuilding.ipv6Prefix}::${builtins.toString machine.address}]:${builtins.toString 9257}" # postfix
                  ])
                  (lib.filter (machine: machine.mailServer.enable) accessibleMachines)
                );
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
    environment.etc = {
      "grafana-dashboards/node-exporter.json" = {
        source = ../resources/dashboards/node-exporter.json;
        group = "grafana";
        user = "grafana";
      };
      "grafana-dashboards/bird2.json" = {
        source = ../resources/dashboards/bird2.json;
        group = "grafana";
        user = "grafana";
      };
      # "grafana-dashboards/restic.json" = {
      #   source = ./grafana-dashboards/restic.json;
      #   group = "grafana";
      #   user = "grafana";
      # };
      # "grafana-dashboards/tor.json" = {
      #   source = ./grafana-dashboards/tor.json;
      #   group = "grafana";
      #   user = "grafana";
      # };
      # "grafana-dashboards/qbittorrent.json" = {
      #   source = ./grafana-dashboards/qbittorrent.json;
      #   group = "grafana";
      #   user = "grafana";
      # };
      # "grafana-dashboards/smartctl.json" = {
      #   source = ./grafana-dashboards/smartctl.json;
      #   group = "grafana";
      #   user = "grafana";
      # };
      # "grafana-dashboards/unpoller.json" = {
      #   source = ./grafana-dashboards/unpoller.json;
      #   group = "grafana";
      #   user = "grafana";
      # };
    };
  };
}
