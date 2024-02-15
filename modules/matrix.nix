{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.modules.matrix;
  baseDomain = cfg.baseDomain;
  turnDomain = "turn.${baseDomain}";
  elementDomain = "element.${baseDomain}";
  synapseDomain = "matrix.${baseDomain}";
  clientConfig."m.homeserver".base_url = "https://${synapseDomain}";
  serverConfig."m.server" = "${synapseDomain}:443";
  mkWellKnown = data: ''
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '${builtins.toJSON data}';
  '';
  email = cfg.certEmail;
in
{
  # coturn secret is imported from /root/secrets.nix
  imports = [
    /root/secrets.nix
  ];

  options.modules.matrix = {
    enable = mkEnableOption "Enable matrix server";

    baseDomain = mkOption {
      type = types.str;
      description = "Base domain for the matrix server. You need to setup the DNS records for this domain and for the matrix, element, and turn subdomains.";
    };

    certEmail = mkOption {
      type = types.str;
      description = "Email address to use for Let's Encrypt certificates.";
    };

    coturn-static-auth-secret = mkOption {
      type = types.str;
      description = "Shared coturn secret for matrix. Should not end up in the git repo";
    };
  };

  config = mkIf cfg.enable {

    # Enable the PostgreSQL service.
    services.postgresql.enable = true;
    services.postgresql.initialScript = pkgs.writeText "synapse-init.sql" ''
      CREATE ROLE "matrix-synapse" WITH LOGIN PASSWORD 'synapse';
      CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
        TEMPLATE template0
        LC_COLLATE = "C"
        LC_CTYPE = "C";
    '';

    # Get certs
    security.acme.acceptTerms = true;
    security.acme.certs = {
      ${baseDomain}.email = email;
      ${elementDomain}.email = email;
      ${synapseDomain}.email = email;
      ${turnDomain} = {
        postRun = "systemctl restart coturn.service";
        email = email;
      };
    };

    services.nginx = {
      enable = true;
      # Only allow PFS-enabled ciphers with AES256
      sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;
      virtualHosts = {
        ${baseDomain} = {
          enableACME = true;
          forceSSL = true;
          locations."= /.well-known/matrix/server".extraConfig = mkWellKnown serverConfig;
          locations."= /.well-known/matrix/client".extraConfig = mkWellKnown clientConfig;
          locations."/.well-known".extraConfig = ''
            try_files $uri $uri/ =404;
          '';
          locations."/".extraConfig = ''
            return 301 $scheme://${elementDomain}$request_uri;
          '';
        };
        ${synapseDomain} = {
          enableACME = true;
          forceSSL = true;
          # Forward all Matrix API calls to the synapse Matrix homeserver. A trailing slash
          # *must not* be used here.
          locations."/_matrix".proxyPass = "http://[::1]:8008";
          # Forward requests for e.g. SSO and password-resets.
          locations."/_synapse/client".proxyPass = "http://[::1]:8008";
          locations."/".extraConfig = ''
            return 301 $scheme://${elementDomain}$request_uri;
          '';
        };
        ${turnDomain} = {
          enableACME = true;
          forceSSL = true;
          # It's also possible to do a redirect here or something else, this vhost is not
          # needed for Matrix. It's recommended though to *not put* element
          # here, see also the section about Element.
          locations."/".extraConfig = ''
            return 301 $scheme://${elementDomain}$request_uri;
          '';
        };
        ${elementDomain} = {
          enableACME = true;
          forceSSL = true;
          serverAliases = [
            elementDomain
          ];

          root = pkgs.element-web.override {
            conf = {
              default_server_config = clientConfig; # see `clientConfig` from the snippet above.
            };
          };
        };
      };
    };

    # enable coturn
    services.coturn = {
      enable = true;
      no-cli = true;
      no-tcp-relay = true;
      min-port = 49000;
      max-port = 50000;
      use-auth-secret = true;
      static-auth-secret = config.modules.matrix.coturn-static-auth-secret;
      realm = turnDomain;
      cert = "${config.security.acme.certs.${turnDomain}.directory}/full.pem";
      pkey = "${config.security.acme.certs.${turnDomain}.directory}/key.pem";
      extraConfig = ''
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

    # open the firewall
    networking.firewall = {
      allowedUDPPortRanges = [{
        from = config.services.coturn.min-port;
        to = config.services.coturn.max-port;
      }];
      allowedUDPPorts = [ 3478 5349 ];
      allowedTCPPortRanges = [ ];
      allowedTCPPorts = [ 80 443 3478 5349 ];
    };

    services.matrix-synapse = {
      enable = true;
      settings.server_name = baseDomain;
      # The public base URL value must match the `base_url` value set in `clientConfig` above.
      # The default value here is based on `server_name`, so if your `server_name` is different
      # from the value of `fqdn` above, you will likely run into some mismatched domain names
      # in client applications.
      settings.public_baseurl = "https://${synapseDomain}";
      settings.listeners = [
        {
          port = 8008;
          bind_addresses = [ "::1" ];
          type = "http";
          tls = false;
          x_forwarded = true;
          resources = [{
            names = [ "client" "federation" ];
            compress = true;
          }];
        }
      ];
      settings.max_upload_size = "500M";

      settings.turn_uris = [ "turn:${config.services.coturn.realm}:3478?transport=udp" "turn:${config.services.coturn.realm}:3478?transport=tcp" ];
      settings.turn_shared_secret = config.services.coturn.static-auth-secret;
      settings.turn_user_lifetime = "1h";
    };

    nixpkgs.config.element-web.conf = {
      show_labs_settings = true;
      default_theme = "dark";
    };
  };
}
