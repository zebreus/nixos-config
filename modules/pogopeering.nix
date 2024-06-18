{ config, lib, ... }: {
  config = lib.mkIf (config.networking.hostName == "sempriaq") {
    age.secrets.pogopeering = {
      file = ../secrets/pogopeering.age;
      mode = "0444";
    };
    networking = {
      domain = "antibuild.ing";


      # Open firewall port for WireGuard.
      firewall = {
        allowedTCPPorts = [ 1 ];

        interfaces.pogopeering = {
          # BGP port
          allowedTCPPorts = [ 179 ];
          # BFD port
          allowedUDPPorts = [ 3784 ];
        };
      };

      # Prevent networkmanager from doing weird stuff with the wireguard interface.
      networkmanager = lib.mkIf config.networking.networkmanager.enable {
        unmanaged = [ "pogopeering" ];
      };

      # Configure the WireGuard interface.
      wireguard.interfaces.pogopeering = {
        ips = [ "aaaa:bbbb:cccc:dddd::1337/64" ];
        allowedIPsAsRoutes = false;
        listenPort = 1;

        # Path to the private key file.
        privateKeyFile = config.age.secrets.pogopeering.path;

        peers =
          [{
            name = "pilz0";
            publicKey = "DZ75UrnScBQlqPKH2vxzIcYJmbJ9rYKmEXc0J2+jgAs=";
            presharedKeyFile = config.age.secrets.shared_wireguard_psk.path;
            # Send keepalives every 25 seconds.
            persistentKeepalive = 25;

            allowedIPs = [ "aaaa:bbbb:cccc:dddd::/64" "fd7a:115c::/32" ];

            # Set this to the server IP and port.
            endpoint = "64.227.147.47:51820";
            dynamicEndpointRefreshSeconds = 60;
          }];
      };
    };
  };

}

