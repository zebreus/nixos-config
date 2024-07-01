{ lib, config, ... }:
let
  machines = lib.attrValues config.machines;
  birdLgServer = lib.head (lib.filter (machine: machine.bird-lg.enable) machines);
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
        ${machine.name}.lg IN AAAA ${config.antibuilding.ipv6Prefix}::${builtins.toString machine.address}
      '')
      machines));
}
