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

  # A Grafana alert rule: instant prometheus query (A) checked against a
  # threshold expression (B). Fires per returned series.
  mkRule = { uid, title, expr, evaluator, for }: {
    inherit uid title for;
    condition = "B";
    data = [
      {
        refId = "A";
        datasourceUid = "prometheus";
        relativeTimeRange = { from = 600; to = 0; };
        model = { inherit expr; instant = true; range = false; refId = "A"; };
      }
      {
        refId = "B";
        datasourceUid = "__expr__";
        relativeTimeRange = { from = 0; to = 0; };
        model = {
          type = "threshold";
          expression = "A";
          refId = "B";
          conditions = [{
            inherit evaluator;
            operator.type = "and";
            query.params = [ "B" ];
            reducer.type = "last";
            type = "query";
          }];
        };
      }
    ];
    noDataState = "OK";
    execErrState = "Error";
    annotations.summary = "${title} on {{ $labels.instance }}";
  };
in
{
  config = lib.mkIf thisMachine.monitoring.enable {
    age.secrets = {
      grafana_secret_key = {
        file = ../secrets/grafana_secret_key.age;
        owner = "grafana";
      };
      grafana_admin_password = {
        file = ../secrets/grafana_admin_password.age;
        owner = "grafana";
      };
    };

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
            enabled = true;
            user = "root@${thisMachine.fqdn}";
            startTLS_policy = "MandatoryStartTLS";
            password = "$__file{${config.age.secrets."${config.networking.hostName}_mail_password".path}}";
            host = "mail.zebre.us:465";
            from_name = "Antibuilding Grafana";
            from_address = config.services.grafana.settings.smtp.user;
          };
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
              options.path = "${../resources/dashboards}";
            }
          ];
          alerting = {
            contactPoints.settings.contactPoints = [{
              name = "grafana-default-email";
              receivers = [{
                uid = "zebreus-email";
                type = "email";
                settings.addresses = "zebreus@zebre.us";
              }];
            }];
            rules.settings.groups = [{
              name = "antibuilding";
              folder = "Alerts";
              interval = "5m";
              rules = [
                (mkRule {
                  uid = "disk-low";
                  title = "Disk almost full";
                  expr = ''node_filesystem_avail_bytes{fstype!~"tmpfs|ramfs|overlay|squashfs"} / node_filesystem_size_bytes'';
                  evaluator = { type = "lt"; params = [ 0.10 ]; };
                  for = "30m";
                })
                (mkRule {
                  uid = "unit-failed";
                  title = "Systemd unit failed";
                  expr = ''sum by (instance) (node_systemd_unit_state{state="failed"})'';
                  evaluator = { type = "gt"; params = [ 0 ]; };
                  for = "15m";
                })
                (mkRule {
                  uid = "target-down";
                  title = "Scrape target down";
                  expr = "up";
                  evaluator = { type = "lt"; params = [ 1 ]; };
                  for = "6h";
                })
                (mkRule {
                  uid = "cert-expiry";
                  title = "Certificate expires soon";
                  expr = "acme_cert_not_after_timestamp_seconds - time()";
                  evaluator = { type = "lt"; params = [ 1209600 ]; }; # 14 days
                  for = "1h";
                })
                (mkRule {
                  uid = "tsdb-size";
                  title = "Prometheus TSDB larger than 20GB";
                  expr = "prometheus_tsdb_storage_blocks_bytes";
                  evaluator = { type = "gt"; params = [ 20000000000 ]; };
                  for = "1h";
                })
              ];
            }];
          };
        };
      };

      prometheus = {
        enable = true;
        listenAddress = "127.0.0.1";
        # Keep metrics forever; the tsdb-size alert warns before this gets big.
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
