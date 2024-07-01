# Establishes wireguard tunnels with all nodes with static IPs as hubs.

# My Host: kashenblade.outside.antibuild.ing
# Wireguard Port: 2
# My Wireguard Public Key: JcKVB23Bwk1D03NfKVsUtPOXOJnzBBNER2Z2m9C3YSk=
# Your Wireguard Public Key: 9TIP7eWcgoCKMBcnMzXS+KfDeoyB0TnVssAK+xYeZjA=
# ASN: 4242421403
# Your ASN: 4242420575
# BGP on link local addresses on port: 179
# My Link Local address in the tunnel: fe80::6970:7636/64
# Your Link Local address in the tunnel:  fe80::497a/64

{ config, lib, ... }:
let
  cfg = config.machines.${config.networking.hostName}.adhdDn42;
in
{
  config = lib.mkIf cfg.enable {
    age.secrets.adhd_dn42 = {
      file = ../../secrets/adhd_dn42.age;
      owner = "systemd-network";
      group = "systemd-network";
    };

    networking = {
      firewall.allowedUDPPorts = [ 3 ];
      firewall.interfaces.adhd_dn42.allowedTCPPorts = [ 179 ];
    };

    systemd.network = {
      netdevs = {
        "50-adhd_dn42" = {
          netdevConfig = {
            Kind = "wireguard";
            Name = "adhd_dn42";
            MTUBytes = "1420";
          };
          wireguardConfig = {
            PrivateKeyFile = config.age.secrets.adhd_dn42.path;
            ListenPort = 3;
          };
          wireguardPeers = [{
            PublicKey = "9TIP7eWcgoCKMBcnMzXS+KfDeoyB0TnVssAK+xYeZjA=";
            AllowedIPs = [ "::/0" "0.0.0.0/0" ];
            PersistentKeepalive = 25;
          }];
        };
      };
      networks.adhd_dn42 = {
        matchConfig.Name = "adhd_dn42";
        address = [ "fe80::6970:7636/64" ];
        routes = [{
          Destination = "fe80::497a/128";
          Scope = "link";
        }];
        networkConfig = {
          IPForward = true;
        };
      };
    };

    services.bird2 = {
      config = lib.mkAfter ''
        protocol bgp adhd_dn42 from dnpeers {
            neighbor fe80::497a%adhd_dn42 as 4242420575;
        }
      '';
    };
  };
}
