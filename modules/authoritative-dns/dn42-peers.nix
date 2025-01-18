{ lib, config, ... }:
let
  machines = lib.attrValues config.machines;
  machinePeerings = builtins.map
    (machine: {
      name = machine.name;
      peerings = machine.dn42Peerings;
    })
    machines;


  records = lib.mkMerge
    ([
      ''
        ; Records for dn42 peerings
      ''
    ] ++
    (builtins.map
      ({ name, peerings }:
        (lib.strings.concatStrings
          (builtins.map
            (peering: ''
              ; Peering ${peering} is running on ${name}
              ${peering}.dn42 IN CNAME ${name}.outside
            '')
            peerings)))
      machinePeerings)
    );
in
{
  config.modules.dns.zones.${config.modules.dns.mainDomain} = records;
}
