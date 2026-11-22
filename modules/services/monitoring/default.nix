{ config, lib, ... }:
let
  thisMachine = config.meta.self;
  exporters = config.services.prometheus.exporters;
  machines = config.meta.accessibleMachines;
  domain = "grafana.${config.meta.domain}";

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
      grafana_secret_key = { };
      grafana_admin_password = { };
    };

    # Grafana and Prometheus run in a gVisor sandbox, which may only connect to
    # the exporters' ports, on the mesh.
    isocon.monitoring = {
      tcpPorts = [{ port = 2342; ipv6 = true; }];
      outgoingTcpPorts = map (port: { inherit port; local = true; internal = true; global = false; }) [ exporters.node.port exporters.bird.port exporters.postfix.port ];
      outgoingUdpPorts = [ ];
      persist = [ "/var/lib/grafana" "/var/lib/prometheus2" ];
      credentials = {
        secret_key = config.age.secrets.grafana_secret_key.path;
        admin_password = config.age.secrets.grafana_admin_password.path;
      };
      config = { config, pkgs, ... }: {
        systemd.services.grafana.serviceConfig.LoadCredential = [ "secret_key" "admin_password" ];
        services.grafana = {
          enable = true;
          declarativePlugins = [ pkgs.grafanaPlugins.prometheus ];
          settings = {
            server = {
              inherit domain;
              http_port = 2342;
              http_addr = "::";
            };
            "auth.anonymous".enabled = true;
            security = {
              secret_key = "$__file{/run/credentials/grafana.service/secret_key}";
              admin_password = "$__file{/run/credentials/grafana.service/admin_password}";
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
            (mkJob "node" exporters.node.port machines)
            (mkJob "bird" exporters.bird.port machines)
            (mkJob "postfix" exporters.postfix.port (lib.filter (machine: machine.mail.enable) machines))
            {
              job_name = "prometheus";
              static_configs = [{ targets = [ "localhost:${toString config.services.prometheus.port}" ]; }];
            }
          ];
        };
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts.${domain} = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://[::1]:2342";
          proxyWebsockets = true;
        };
      };
    };
  };
}
