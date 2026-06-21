{ lib, config, pkgs, ... }:
let
  primaryName = config.meta.services.dns.primary;
  # The authoritative DNS servers are exactly the hosts assigned to the dns
  # service; the primary is named directly by the service.
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
  secondaryServers = lib.filter (machine: machine.name != primaryName) machinesThatAreAuthoritativeDnsServers;
  thisServer = config.meta.self;

  knotZonesEnv = pkgs.buildEnv {
    name = "knot-zones";
    paths = (lib.mapAttrsToList (name: value: pkgs.writeTextDir "${name}.zone" value) config.modules.dns.zones);
  };
in
{
  options = {
    modules.dns.zones = lib.mkOption {
      default = { };
      description = "DNS zones";
      type = with lib.types; attrsOf (lines);
      example = {
        "antibuild.ing" = ''
          @ IN A 1.1.1.1
        '';
        "zeb.rs" = ''
          @ IN A 1.1.1.1
        '';
      };
    };
    modules.dns.mainDomain = lib.mkOption {
      default = config.meta.domain;
      description = "The main domain for internal services. Used for stuff like nameservers.";
      type = lib.types.str;
    };
  };

  config = lib.mkIf thisServer.dns.enable
    {
      age.secrets.knot_transport_key = {
        file = ../../secrets/knot_transport_key.age;
        owner = "knot";
        group = "knot";
        mode = "0400";
      };

      networking.firewall.allowedTCPPorts = [ 53 ];
      networking.firewall.allowedUDPPorts = [ 53 ];
      services.knot = {
        enable = true;
        keyFiles = [ config.age.secrets.knot_transport_key.path ];
        settings =
          {
            remote = builtins.map
              # TODO: Verify that autodiscovery works like this
              (machine: {
                id = machine.name;
                key = "knot_transfer_key";
                address = builtins.map (ip: "${ip}@53") machine.ips;
              })
              machinesThatAreAuthoritativeDnsServers;

            server = {
              listen = builtins.map (addr: "${addr}@53") (builtins.filter
                (e: e != null)
                [ thisServer.staticIp4 thisServer.staticIp6 "${thisServer.antibuildingIp6}" ]);
            };
            log.syslog.any = "info";
            template.default = {
              # Input-only zone files
              # https://www.knot-dns.cz/docs/2.8/html/operation.html#example-3
              # prevents modification of the zonefiles, since the zonefiles are immutable
              zonefile-sync = -1;
            };
            acl = [
              {
                id = "transfer_antibuilding";
                key = "knot_transfer_key";
                address = builtins.concatMap (machine: machine.ips) (secondaryServers ++ primaryServers);
                # [ "${config.meta.ipv6Prefix}::/64" "167.235.154.30" "49.13.8.171/32" "192.227.228.220/32" ];
                action = [ "transfer" ];
              }
              {
                id = "notify_antibuilding";
                key = "knot_transfer_key";
                address = builtins.concatMap (machine: machine.ips) (secondaryServers ++ primaryServers);
                action = [ "notify" ];
              }
            ];
            policy = [
              {
                id = "normal-signatures";
                signing-threads = 2;
                algorithm = "ECDSAP256SHA256";
                zsk-lifetime = "17d";
                ksk-lifetime = "0";
                reproducible-signing = true;
              }
            ];

            zone = (lib.mapAttrs
              (name: _: (if thisServer.dns.primary then {
                storage = knotZonesEnv;
                file = "${name}.zone";
                notify = builtins.map (machine: machine.name) secondaryServers;
                acl = [ "transfer_antibuilding" ];
                dnssec-signing = true;
                dnssec-policy = "normal-signatures";

                zonefile-load = "difference-no-serial";
                journal-content = "all";
                serial-policy = "dateserial";
              } else {
                storage = knotZonesEnv;
                file = "${name}.zone";
                master = builtins.map (machine: machine.name) primaryServers;
                acl = [ "notify_antibuilding" ];
                dnssec-signing = false;

                zonefile-load = "none";
                journal-content = "all";
              }))
              config.modules.dns.zones);
          };
      };
    };
}
