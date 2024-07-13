{ lib, config, ... }:
let
  machinesThatAreAuthoritativeDnsServers = builtins.map
    (machine: machine // {
      ips = ([ "${config.antibuilding.ipv6Prefix}::${builtins.toString machine.address}" ] ++
        (if machine.staticIp4 != null then [ "${machine.staticIp4}" ] else [ ]) ++
        (if machine.staticIp6 != null then [ "${machine.staticIp6}" ] else [ ]));
    })
    (lib.attrValues
      (lib.filterAttrs (name: machine: machine.authoritativeDns.enable) config.machines));
  primaryServers = lib.filter (machine: machine.authoritativeDns.primary) machinesThatAreAuthoritativeDnsServers;
  thisServer = lib.head (lib.attrValues (lib.filterAttrs (name: machine: name == config.networking.hostName) config.machines));

  voidspaceZones = [
    "haaien.xyz"
  ];
in
{
  config = lib.mkIf thisServer.authoritativeDns.enable
    {
      age.secrets.dns_voidspace_antibuilding_tsig_key = {
        file = ../../secrets/dns_voidspace_antibuilding_tsig_key.age;
        owner = "knot";
        group = "knot";
        mode = "0400";
      };

      services.knot = {
        keyFiles = [ config.age.secrets.dns_voidspace_antibuilding_tsig_key.path ];
        settings =
          {
            remote = [{
              id = "ns1_izzie";
              key = "dns_voidspace_antibuilding_tsig_key";
              address = [ "fd49:7a7a:6965:1::1@53" ];
            }];

            acl = [
              {
                id = "notify_voidspace";
                key = "dns_voidspace_antibuilding_tsig_key";
                address = [ "fd49:7a7a:6965:1::1" ];
                action = [ "notify" ];
              }
              {
                id = "transfer_voidspace";
                key = "knot_transfer_key";
                address = [ "fd49:7a7a:6965:1::1" ];
                action = [ "transfer" ];
              }
            ];

            zone =
              # Process notifies from the voidspace
              (builtins.listToAttrs (map
                (zone: {
                  name = zone;
                  value = (if thisServer.authoritativeDns.primary then {
                    master = [ "ns1_izzie" ];
                    acl = [ "notify_voidspace" "transfer_antibuilding" ];

                    zonefile-load = "none";
                    journal-content = "all";
                  } else {
                    master = builtins.map (machine: machine.name) primaryServers;
                    acl = "notify_antibuilding";

                    zonefile-load = "none";
                    journal-content = "all";
                  });
                })
                voidspaceZones))
              //
              # Send notifies and allow transfers to the voidspace
              (if thisServer.authoritativeDns.primary then
                (builtins.listToAttrs (map
                  (zone: {
                    name = zone;
                    value = {
                      acl = [ "transfer_voidspace" ];
                    };
                  })
                  (builtins.attrNames config.modules.dns.zones))) else { });
          };
      };
    };
}
