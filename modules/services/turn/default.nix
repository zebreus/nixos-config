{ lib, config, ... }:
let
  cfg = config.meta.self.turn;
  inherit (config.meta.self) staticIp4 staticIp6;
  # Below the host's ephemeral ports: pasta can't start if one of them is taken.
  relayPorts = { from = 20000; to = 21000; };
in
{
  imports = [ ./dns.nix ];

  config = lib.mkIf cfg.enable {
    age.secrets.coturn_static_auth_secret = { };

    # coturn in a gVisor sandbox. pasta forwards the host's ports to the same
    # ports of the guest and sends the guest's datagrams from them, so coturn
    # works as behind a NAT that maps ports 1:1.
    isocon.turn = {
      tcpPorts = [{ port = 3478; mode = "global"; ipv6 = true; }];
      udpPorts = map (port: { inherit port; mode = "global"; ipv6 = true; }) [ 3478 "${toString relayPorts.from}-${toString relayPorts.to}" ];
      # The relay sends to whatever port a peer uses.
      outgoingUdpPorts = [{ port = "1-65535"; }];
      credentials.auth_secret = config.age.secrets.coturn_static_auth_secret.path;
      config = {
        systemd.services.coturn.serviceConfig.LoadCredential = [ "auth_secret" ];
        services.coturn = {
          enable = true;
          realm = "turn.${cfg.baseDomain}";
          no-cli = true;
          # Synapse only hands out turn: URIs.
          no-tls = true;
          no-dtls = true;
          no-tcp-relay = true;
          min-port = relayPorts.from;
          max-port = relayPorts.to;
          use-auth-secret = true;
          static-auth-secret-file = "/run/credentials/coturn.service/auth_secret";
          # The guest's addresses, see isocon's network.nix.
          listening-ips = [ "10.0.2.2" "fd00::2" ];
          relay-ips = [ "10.0.2.2" "fd00::2" ];
          extraConfig = ''
            # What pasta forwards to the guest's addresses.
            external-ip=${staticIp4}/10.0.2.2
            external-ip=${staticIp6}/fd00::2
            # for debugging
            verbose
            # ban private IP ranges
            no-multicast-peers
            denied-peer-ip=0.0.0.0-0.255.255.255
            denied-peer-ip=10.0.0.0-10.255.255.255
            denied-peer-ip=100.64.0.0-100.127.255.255
            denied-peer-ip=127.0.0.0-127.255.255.255
            denied-peer-ip=169.254.0.0-169.254.255.255
            denied-peer-ip=172.16.0.0-172.31.255.255
            denied-peer-ip=192.0.0.0-192.0.0.255
            denied-peer-ip=192.0.2.0-192.0.2.255
            denied-peer-ip=192.88.99.0-192.88.99.255
            denied-peer-ip=192.168.0.0-192.168.255.255
            denied-peer-ip=198.18.0.0-198.19.255.255
            denied-peer-ip=198.51.100.0-198.51.100.255
            denied-peer-ip=203.0.113.0-203.0.113.255
            denied-peer-ip=240.0.0.0-255.255.255.255
            denied-peer-ip=::1
            denied-peer-ip=64:ff9b::-64:ff9b::ffff:ffff
            denied-peer-ip=::ffff:0.0.0.0-::ffff:255.255.255.255
            denied-peer-ip=100::-100::ffff:ffff:ffff:ffff
            denied-peer-ip=2001::-2001:1ff:ffff:ffff:ffff:ffff:ffff:ffff
            denied-peer-ip=2002::-2002:ffff:ffff:ffff:ffff:ffff:ffff:ffff
            denied-peer-ip=fc00::-fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
            denied-peer-ip=fe80::-febf:ffff:ffff:ffff:ffff:ffff:ffff:ffff
          '';
        };
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ 3478 ];
      allowedUDPPorts = [ 3478 ];
      allowedUDPPortRanges = [ relayPorts ];
    };
  };
}
