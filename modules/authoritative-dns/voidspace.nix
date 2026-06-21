{ lib, config, ... }:
let
  primaryName = config.meta.services.dns.primary;
  machinesThatAreAuthoritativeDnsServers = builtins.map
    (name:
      let machine = config.meta.machines.${name}; in
      machine // {
        ips = ([ "${machine.antibuildingIp6}" ] ++
        (if machine.staticIp4 != null then [ "${machine.staticIp4}" ] else [ ]) ++
        (if machine.staticIp6 != null then [ "${machine.staticIp6}" ] else [ ]));
      })
    (builtins.attrNames config.meta.services.dns.hosts);
  primaryServers = lib.filter (machine: machine.name == primaryName) machinesThatAreAuthoritativeDnsServers;
  thisServer = config.meta.self;

  voidspaceZones = [
    "haaien.xyz"
  ];
in
{
  config = lib.mkMerge [
    (lib.mkIf thisServer.dns.primary {
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
                key = "dns_voidspace_antibuilding_tsig_key";
                address = [ "fd49:7a7a:6965:1::1" ];
                action = [ "transfer" ];
              }
            ];

            zone =
              # Process notifies from the voidspace
              (builtins.listToAttrs (map
                (zone: {
                  name = zone;
                  value = {
                    master = [ "ns1_izzie" ];
                    acl = [ "notify_voidspace" "transfer_antibuilding" ];

                    zonefile-load = "none";
                    journal-content = "all";
                  };
                })
                voidspaceZones))
              //
              # Send notifies and allow transfers to the voidspace
              (builtins.listToAttrs (map
                (zone: {
                  name = zone;
                  value = {
                    acl = [ "transfer_voidspace" ];
                  };
                })
                (builtins.attrNames config.modules.dns.zones)));
          };
      };
    })
    (lib.mkIf thisServer.dns.secondary {
      services.knot = {
        settings =
          {
            # Allow secondaries to be notified by the primary of voidspace zones
            zone = builtins.listToAttrs (map
              (zone: {
                name = zone;
                value = {
                  master = builtins.map (machine: machine.name) primaryServers;
                  acl = "notify_antibuilding";
                  zonefile-load = "none";
                  journal-content = "all";
                };
              })
              voidspaceZones);
          };
      };
    })
  ];
}
