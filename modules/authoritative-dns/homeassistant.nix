{ lib, config, ... }:
let
  host = config.meta.services.homeassistant.host;
  server = config.meta.machines.${host};
in
{
  config = lib.mkIf (host != null) {
    modules.dns.zones."zebre.us" = ''
      ; Records for homeassistant
      ; hass IN A ${server.staticIp4}
      hass IN AAAA ${server.staticIp6}
      internal.hass IN A 192.168.178.43
      internal.hass IN AAAA ${server.staticIp6}
    '';
  };
}
