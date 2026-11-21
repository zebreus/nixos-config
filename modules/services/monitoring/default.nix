{ config, lib, ... }:
let
  thisMachine = config.meta.self;
  exporters = config.services.prometheus.exporters;

  mkJob = job_name: port: machines: {
    inherit job_name;
    static_configs = [{
      targets = builtins.map (machine: "[${machine.antibuildingIp6}]:${toString port}") machines;
    }];
  };
in
{
  imports = [ ./dns.nix ];

  config = lib.mkIf thisMachine.monitoring.enable {
    age.secrets = {
      grafana_secret_key = {
        owner = "grafana";
      };
      grafana_admin_password = {
        owner = "grafana";
      };
    };

    isocon.monitoring = {
      config = {
        services.grafana = {
          enable = true;
          settings = {
            server = {
              domain = "grafana.${config.meta.domain}";
              http_port = 2342;
              http_addr = "::1";
            };
            "auth.anonymous".enabled = true;
            security = {
              secret_key = "$__file{${config.age.secrets.grafana_secret_key.path}}";
              admin_password = "$__file{${config.age.secrets.grafana_admin_password.path}}";
            };
          };
          provision = {
            enable = true;
            datasources.settings.datasources = [
              {
                type = "prometheus";
                isDefault = true;
                name = "prometheus";
                uid = "prometheus";
                url = "http://localhost:${toString config.services.prometheus.port}";
              }
            ];
            dashboards.settings.providers = [
              {
                name = "My Dashboards";
                options.path = "${../../../resources/dashboards}";
              }
            ];
          };
        };

        services.prometheus = {
          enable = true;
          listenAddress = "127.0.0.1";
          retentionTime = "99y";
          scrapeConfigs = [
            (mkJob "node" exporters.node.port config.meta.accessibleMachines)
            (mkJob "bird" exporters.bird.port config.meta.accessibleMachines)
            (mkJob "postfix" exporters.postfix.port (lib.filter (machine: machine.mail.enable) config.meta.accessibleMachines))
            {
              job_name = "prometheus";
              static_configs = [{ targets = [ "localhost:${toString config.services.prometheus.port}" ]; }];
            }
          ];
        };

      };
    };
    services = {
      nginx = {
        enable = true;
        virtualHosts."grafana.${config.meta.domain}" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://[::1]:2342";
            proxyWebsockets = true;
          };
        };
      };
    };
  };
}
