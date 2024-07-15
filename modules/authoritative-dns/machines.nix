{ lib, config, ... }:
let
  machines = lib.attrValues config.machines;
  serversWithStaticIpv4 = lib.filter (machine: machine.staticIp4 != null) machines;
  serversWithStaticIpv6 = lib.filter (machine: machine.staticIp6 != null) machines;

  records = lib.mkMerge
    ([
      ''
        ; Records for globally reachable static ips
      ''
    ] ++
    (builtins.map
      (machine: ''
        ; Public ipv4 entry for ${machine.name}
        ${machine.name}.outside IN A ${builtins.toString machine.staticIp4}
      '')
      serversWithStaticIpv4)
    ++
    (builtins.map
      (machine: ''
        ; Public ipv6 entry for ${machine.name}
        ${machine.name}.outside IN AAAA ${builtins.toString machine.staticIp6}
      '')
      serversWithStaticIpv6)
    ++
    (builtins.map
      (machine: ''
        ; Internal for ${machine.name}
        ${machine.name} IN AAAA ${config.antibuilding.ipv6Prefix}::${builtins.toString machine.address}
        ${machine.name} IN A 172.20.179.${builtins.toString (machine.address + 128)}
        ; For the bird2 lookingglass
        ${machine.name}.lg IN AAAA ${config.antibuilding.ipv6Prefix}::${builtins.toString machine.address}
      '')
      machines)
    );
in
{
  config.modules.dns.zones.${config.modules.dns.mainDomain} = records;
  config.modules.dns.zones."antibuilding.dn42" = records;

  # dn42 reverse dns
  config.modules.dns.zones."128/27.179.20.172.in-addr.arpa" = lib.mkMerge (builtins.map
    (machine: ''
      ${builtins.toString (machine.address + 128)} PTR ${machine.name}.antibuilding.dn42
    '')
    machines);
  config.modules.dns.zones."0.0.0.0.0.3.0.2.0.1.d.f.ip6.arpa" = lib.mkMerge (builtins.map
    (machine: ''
      ${lib.concatStringsSep "." (lib.reverseList (lib.stringToCharacters (lib.fixedWidthString 20 "0" (builtins.toString machine.address))))} PTR ${machine.name}.antibuilding.dn42
    '')
    machines);
}
