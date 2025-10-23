{ lib, config, ... }:
let
  machines = lib.attrValues config.machines;
  eventServer = lib.head (lib.filter (machine: machine.photosServer.enable) machines);
  baseDomain = "zebre.us";
in
{
  config.modules.dns.zones."${baseDomain}" = ''
    ; Records for $
    photos IN A ${eventServer.staticIp4}
    photos IN AAAA ${eventServer.staticIp6}
  '';
}
