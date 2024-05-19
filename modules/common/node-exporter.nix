{ config, ... }:
let thisMachine = config.machines."${config.networking.hostName}";
in
{
  config = {
    services.prometheus = {
      exporters.node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        listenAddress = "[${config.antibuilding.ipv6Prefix}::${builtins.toString thisMachine.address}]";
        port = 9100;
        openFirewall = true;
        firewallFilter = "-i antibuilding";
      };
    };
  };
}
