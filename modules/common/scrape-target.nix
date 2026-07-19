# Prometheus exporters declare their port here; the firewall opens it to the
# monitoring host (exactlyOne) and nothing else.
{ config, lib, ... }:
{
  options.monitoring.scrapePorts = lib.mkOption {
    type = lib.types.listOf lib.types.port;
    default = [ ];
    description = "Exporter ports on this machine that the monitoring host may scrape.";
  };

  config = lib.mkIf (config.monitoring.scrapePorts != [ ]) {
    networking.firewall.extraInputRules = ''
      ip6 saddr ${config.meta.machines.${config.meta.services.monitoring.host}.antibuildingIp6}/128 tcp dport { ${lib.concatMapStringsSep ", " toString config.monitoring.scrapePorts} } accept
    '';
  };
}
