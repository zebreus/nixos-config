{ config, ... }:
{
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "systemd" ];
    listenAddress = "[${config.meta.self.antibuildingIp6}]";
  };
  monitoring.scrapePorts = [ config.services.prometheus.exporters.node.port ];
}
