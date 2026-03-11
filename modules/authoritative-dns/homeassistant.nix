{ lib, config, ... }:
let
  machines = lib.attrValues config.machines;
  homeassistantServers = lib.filter (machine: machine.homeassistantServer.enable) machines;
in
{
  config = lib.mkIf ((builtins.length homeassistantServers) == 1) (
    let homeassistantServer = lib.head homeassistantServers; in {
      modules.dns.zones."zebre.us" = ''
        ; Records for homeassistant
        hass IN A 192.168.178.24
        ; hass IN AAAA 0::
      '';
    }
  );
}
