{ lib, config, ... }:
let
  inherit (import ./helper.nix { inherit lib; }) quoteTxtEntry;

  thisServer = lib.head (lib.attrValues (lib.filterAttrs (name: machine: name == config.networking.hostName) config.machines));
  routedbitsDn42Server = lib.head (lib.attrValues (lib.filterAttrs (name: machine: machine.routedbitsDn42.enable) config.machines));
in
{
  config.modules.dns.zones = lib.mkIf thisServer.authoritativeDns.enable (
    {
      # Used for infrastructure and internal names
      "antibuild.ing" = ''
        ; routedbits peering
        de1.routedbits IN A ${routedbitsDn42Server.staticIp4}
        de1.routedbits IN AAAA ${routedbitsDn42Server.staticIp6}
      '';

      # I use this domains for hosting random stuff with github pages
      "wirs.ing" = ''
        ; various github pages
        @	IN A 185.199.108.153
        @	IN A 185.199.109.153
        @	IN A 185.199.110.153
        @	IN A 185.199.111.153
        @	IN AAAA 2606:50c0:8000::153
        @	IN AAAA 2606:50c0:8001::153
        @	IN AAAA 2606:50c0:8002::153
        @	IN AAAA 2606:50c0:8003::153
        ofborg IN CNAME zebreus.github.io.
        search IN CNAME zebreus.github.io.
        second IN CNAME zebreus.github.io.
        coreboot IN CNAME zebreus.github.io.
        custom IN CNAME zebreus.github.io.
        _github-pages-challenge-zebreus IN TXT ${quoteTxtEntry "3a57be146a6065e7abbae1a5783afa"}
      '';

      # Hosts a badly drawn picture of a unicorn
      "einhorn.jetzt" = ''
        ; github pages
        _github-pages-challenge-zebreus IN TXT ${quoteTxtEntry "039c1f2cef900279d730d61bbf2295"}
        @	IN A 185.199.108.153
        @	IN A 185.199.109.153
        @	IN A 185.199.110.153
        @	IN A 185.199.111.153
        @	IN AAAA 2606:50c0:8000::153
        @	IN AAAA 2606:50c0:8001::153
        @	IN AAAA 2606:50c0:8002::153
        @	IN AAAA 2606:50c0:8003::153
        www IN CNAME zebreus.github.io.

        ; google site verification
        @ IN TXT ${quoteTxtEntry "google-site-verification=N11GiQq5grX82UY2Ik0dn4AQ7NpFd4dl_Sg2G2BYrvU"}
      '';

      # Hosts a now defunct and unfinished project for ai generated shirts
      "generated.fashion" = ''
        ; generated.fashion on hosted on vercel
        @	IN A 76.76.21.21
        www	IN CNAME cname.vercel-dns.com.

        ; google site verification
        @ IN TXT ${quoteTxtEntry "google-site-verification=6B_Cig2VbMktIY9q13NowVz_5bZ1bQLgSOdFgVqpuzQ"}
      '';

      # Hosts a broken test of a gunjs based blog
      "xn--f87c.cc" = ''
        ; blog test on vercel
        @	IN A 76.76.21.21
        www	IN CNAME cname.vercel-dns.com.
        testing IN NS ns1.vercel-dns.com.
      '';
    }
  );
}
