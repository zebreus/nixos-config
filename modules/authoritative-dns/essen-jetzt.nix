{ lib, config, ... }:
let
  machines = lib.attrValues config.machines;
  essenJetztServer = lib.head (lib.filter (machine: machine.essenJetztServer.enable) machines);
in
{
  config.modules.dns.zones."essen.jetzt" = ''
    ; Records for essen.jetzt
    @ IN A ${essenJetztServer.staticIp4}
    @ IN AAAA ${essenJetztServer.staticIp6}
  '';
}
