{ lib, config, ... }:
let
  host = config.meta.services.essenJetzt.host;
  server = config.meta.machines.${host};
in
{
  config.modules.dns.zones = lib.mkIf (host != null) {
    "essen.jetzt" = ''
      ; Records for essen.jetzt
      @ IN A ${server.staticIp4}
      @ IN AAAA ${server.staticIp6}
    '';
    "rudelb.link" = ''
      ; Records for essen.jetzt
      man IN A ${server.staticIp4}
      man IN AAAA ${server.staticIp6}
    '';
  };
}
