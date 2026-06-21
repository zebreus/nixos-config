{ lib, config, ... }:
let
  machines = lib.attrValues config.meta.machines;
  # bird-lg is exactlyOne, so the service always names exactly one host.
  birdLgServer = config.meta.machines.${config.meta.services.bird-lg.host};
in
{
  config.modules.dns.zones.${config.modules.dns.mainDomain} = ''
    ; bird looking-glass
    lg IN A ${birdLgServer.staticIp4}
    lg IN AAAA ${birdLgServer.staticIp6}
  '' +
  (builtins.concatStringsSep "\n" (
    builtins.map
      (machine: ''
        ; Bird looking-glass proxy record for ${machine.name}
        ${machine.name}.lg IN AAAA ${machine.antibuildingIp6}
      '')
      machines));
}
