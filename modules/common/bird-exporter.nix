{ config, ... }:
{
  services.prometheus.exporters.bird = {
    enable = true;
    listenAddress = "[${config.meta.self.antibuildingIp6}]";
  };
  monitoring.scrapePorts = [ config.services.prometheus.exporters.bird.port ];
}
