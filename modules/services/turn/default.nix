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
      # 9641 is coturn's metrics exporter.
      tcpPorts = map (port: { inherit port; mode = "global"; ipv6 = true; }) [ 3478 9641 ];
      udpPorts = map (port: { inherit port; mode = "global"; ipv6 = true; }) [ 3478 "${toString relayPorts.from}-${toString relayPorts.to}" ];
      # The relay sends to whatever port a peer uses. Only on public
      # addresses, which keeps it off private ones without coturn's
      # denied-peer-ip.
      outgoingUdpPorts = [{ port = "1-65535"; }];
      credentials.auth_secret = config.age.secrets.coturn_static_auth_secret.path;
      config = {
        systemd.services.coturn.serviceConfig.LoadCredential = [ "auth_secret" ];
        services.coturn = {
          enable = true;
          realm = "turn.${cfg.baseDomain}";
          # Synapse only hands out turn: URIs.
          no-tls = true;
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
            no-software-attribute
            prometheus
          '';
        };
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ 3478 ];
      allowedUDPPorts = [ 3478 ];
      allowedUDPPortRanges = [ relayPorts ];
    };
    monitoring.scrapePorts = [ 9641 ];
  };
}
