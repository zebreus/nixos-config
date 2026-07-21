# Export the expiry of every ACME certificate on this machine as a node
# exporter textfile metric, so monitoring can warn before a cert expires
# (e.g. when renewals fail silently).
{ pkgs, ... }:
let
  textfileDir = "/var/lib/prometheus-node-exporter/textfiles";
in
{
  services.prometheus.exporters.node.extraFlags = [ "--collector.textfile.directory=${textfileDir}" ];
  systemd.tmpfiles.rules = [ "d ${textfileDir} 0755 root root -" ];

  systemd.timers.acme-metrics = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "6h";
    };
  };
  systemd.services.acme-metrics = {
    path = [ pkgs.openssl ];
    serviceConfig.Type = "oneshot";
    script = ''
      shopt -s nullglob
      {
        echo "# TYPE acme_cert_not_after_timestamp_seconds gauge"
        for cert in /var/lib/acme/*/cert.pem; do
          name=$(basename "$(dirname "$cert")")
          not_after=$(openssl x509 -in "$cert" -noout -enddate | cut -d= -f2)
          echo "acme_cert_not_after_timestamp_seconds{cert=\"$name\"} $(date -d "$not_after" +%s)"
        done
      } > ${textfileDir}/acme.prom.tmp
      mv ${textfileDir}/acme.prom.tmp ${textfileDir}/acme.prom
    '';
  };
}
