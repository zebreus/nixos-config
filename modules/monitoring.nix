{ config, lib, pkgs, ... }:
let
  thisMachine = config.meta.self;
  accessibleMachines = config.meta.accessibleMachines;
in
{
  config = lib.mkIf thisMachine.monitoring.enable {
    services = {
      grafana = {
        enable = true;
        settings = {
          server = {
            domain = "grafana.${config.meta.domain}";
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
            user = "root@${config.meta.self.fqdn}";
            startTLS_policy = "MandatoryStartTLS";
            password = "$__file{${config.age.secrets."${config.networking.hostName}_mail_password".path}}";
            host = "mail.zebre.us:465";
            from_name = "Antibuilding Grafana";
            from_address = config.services.grafana.settings.smtp.user;
          };
          # Hard coding the key that was previously default
          security.secret_key = "SW2YcwTIb9zpOOhoPsMm";
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
                    "[${machine.antibuildingIp6}]:${builtins.toString config.services.prometheus.exporters.node.port}"
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
                    "[${machine.antibuildingIp6}]:${builtins.toString config.services.prometheus.exporters.bird.port}"
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
                    "[${machine.antibuildingIp6}]:${builtins.toString 9256}" # rspamd
                    "[${machine.antibuildingIp6}]:${builtins.toString 9257}" # postfix
                  ])
                  (lib.filter (machine: machine.mail.enable) accessibleMachines)
                );
              }
            ];
          }
        ];
      };
      nginx = {
        enable = true;
        virtualHosts = {
          "grafana.${config.meta.domain}" = {
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
