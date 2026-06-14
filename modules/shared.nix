# TODO: Move somewhere else
{ config, lib, ... }: {



  # Keep the classic dbus-daemon. Recent nixpkgs defaults the implementation to
  # dbus-broker, which is flagged as a critical component change and blocks
  # `nixos-rebuild switch`. Pinning "dbus" avoids the switch inhibitor.
  services.dbus.implementation = "dbus";

  security.acme = {
    acceptTerms = true;
    defaults.webroot = "/var/lib/acme/acme-challenge/";
    defaults.email = "lennarteichhorn@googlemail.com";
    defaults.group = "nginx";
  };

  services.nginx = {
    # Only allow PFS-enabled ciphers with AES256
    sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
  };

  networking.firewall = lib.mkIf config.services.nginx.enable {
    allowedTCPPorts = [ 80 443 ];
  };
}
