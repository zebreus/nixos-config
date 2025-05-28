# dn42 peering information
{ ... }:
{
  config = {
    modules.dn42.peerings = {
      echonet = {
        peerLinkLocal = "fe80::715";
        ownLinkLocal = "fe80::1234:5678";
        asNumber = "4242420714";
        publicWireguardEndpoint = "de01.dn42.lare.cc:21403";
        publicWireguardKey = "UrANRZ2S0WzUbo3cCIbT0PP/VAucFFeGLNP3aY/ovyM=";
        publicWireguardPort = "5";
      };
      adhd = {
        peerLinkLocal = "fe80::497a";
        ownLinkLocal = "fe80::6970:7636";
        asNumber = "4242420575";
        # publicWireguardEndpoint = "de01.dn42.lare.cc:21403";
        publicWireguardKey = "9TIP7eWcgoCKMBcnMzXS+KfDeoyB0TnVssAK+xYeZjA=";
        publicWireguardPort = "3";
      };
      kioubit_de2 = {
        peerLinkLocal = "fe80::ade0";
        ownLinkLocal = "fe80::1920:4444";
        asNumber = "4242423914";
        publicWireguardEndpoint = "de2.g-load.eu:21403";
        publicWireguardKey = "B1xSG/XTJRLd+GrWDsB06BqnIq8Xud93YVh/LYYYtUY=";
      };
      larede01 = {
        peerLinkLocal = "fe80::3035:130";
        ownLinkLocal = "fe80::4249:7543";
        asNumber = "4242423035";
        publicWireguardEndpoint = "de01.dn42.lare.cc:21403";
        publicWireguardKey = "OL2LE2feDsFV+fOC4vo4u/1enuxf3m2kydwGRE2rKVs=";
        publicWireguardPort = "4";
      };
      routedbits_de1 = {
        peerLinkLocal = "fe80::207";
        ownLinkLocal = "fe80::1920:3289";
        asNumber = "4242420207";
        publicWireguardEndpoint = "router.fra1.routedbits.com:51403";
        publicWireguardKey = "FIk95vqIJxf2ZH750lsV1EybfeC9+V8Bnhn8YWPy/l8=";
        publicWireguardPort = "57319";
      };
      pogopeering = {
        peerLinkLocal = "fe80::1312";
        ownLinkLocal = "fe80::acab";
        asNumber = "4242420663";
        publicWireguardEndpoint = "de01.dn42.lare.cc:21403";
        publicWireguardKey = "NxHkdwZPVL+3HdrHTFOslUpUckTf0dzEG9qpZ0FTBnA=";
        publicWireguardPort = "1";
      };
      sebastians = {
        peerLinkLocal = "fe80::cafe";
        ownLinkLocal = "fe80::beef";
        asNumber = "4242420611";
        publicWireguardEndpoint = "pioneer.sebastians.dev:51822";
        publicWireguardKey = "saICY1kV8JbuPOQNQLtm9TnVP2CuxC0qFSkd69pEKQQ=";
        publicWireguardPort = "2";
      };
      aprl = {
        peerLinkLocal = "fe80::1442:1";
        ownLinkLocal = "fe80::1234:9320";
        asNumber = "4242422593";

        publicWireguardKey = "d/cmokBfb0WatQ+xHxe02YOcrV2vuZtKeJp4H0pseTg=";
        publicWireguardPort = "29362";
        # My public key: IR9h1sRdPK+yyzOCpy93axXTs4aLbUaVskniguYMIw0=
      };
      lgcl = {
        peerLinkLocal = "fe80::4d:6172:6379";
        ownLinkLocal = "fe80::1234:9320";
        asNumber = "4242421825";

        publicWireguardKey = "5EW7R+x2LUsfKT8kf9mh2cvaEM/J9TB8LTEOI6GsQgg=";
        publicWireguardPort = "10933";
        # My public key: jW8LkLPgcCM16I1fUfWrkjP9nP7XguOkjsslPWts2BQ=
        # My endpoint: lgcl.dn42.antibuild.ing:10933
        # My AS: 4242421403
      };
      ellie = {
        peerLinkLocal = "fe80::8943:2034:2342";
        ownLinkLocal = "fe80::1234:9320";
        asNumber = "4242421111";

        publicWireguardKey = "/68diNYU0Lsa+gQ/FS8uaRoU0eYICc/xvaLo7yFSgCA=";
        publicWireguardPort = "17230";
        # My public key: l0Vzs8CKYTJooVtkKJlS7WRtSN9umo9EHodv9FnCCko=
        # My endpoint: ellie.dn42.antibuild.ing:17230
        # My AS: 4242421403
      };
      tech9_de02 = {
        peerLinkLocal = "fe80::1588";
        ownLinkLocal = "fe80::100";
        asNumber = "4242421588";
        publicWireguardEndpoint = "de-fra02.dn42.tech9.io:52172";
        publicWireguardKey = "MD1EdVe9a0yycUdXCH3A61s3HhlDn17m5d07e4H33S0=";
        publicWireguardPort = "12913";
        # My public key: khMFUGJIHcuUHJln3PmcSHv1kv+ZR/HmBbRkCI1XGyU=
        # My endpoint: tech9_de02.dn42.antibuild.ing:12913
        # My AS: 4242421403
      };
      stephanj = {
        peerLinkLocal = "fe80::8943:2034:2342";
        ownLinkLocal = "fe80::1234:9320";
        asNumber = "64674";

        publicWireguardEndpoint = "proxyvm.stejau.de:56415";
        publicWireguardKey = "N2GzXIVIxHTZpyPOkw1D8DX6Hyo6YWQOdMXJ2DswgW0=";
        publicWireguardPort = "15133";
        # My public key: vZyOA4Kj+Si9OmakDnEKiS1kWYmjkkui4jdeI+iraSg=
        # My endpoint: stephanj.dn42.antibuild.ing:15133
        # My AS: 4242421403
        #
        # !!! Make sure to restart the other sides wireguard AFTER we deployed our DNS config
      };
      decade = {
        peerLinkLocal = "fe80::8943:2034:2342";
        ownLinkLocal = "fe80::1234:9320";
        asNumber = "4242420069";

        publicWireguardKey = "IRkZN2ZvfDBG/EZwH1ak/8047mIK4FPgke53cOibDkw=";
        publicWireguardPort = "5241";
        # My public key: 7lS7x+2NVx7FQgdN6qpioF8nJn95mBkctv3Gg4h/lDA=
        # My endpoint: decade.dn42.antibuild.ing:5241
        # My AS: 4242421403
        #
        # !!! Make sure to restart the other sides wireguard AFTER we deployed our DNS config
      };
      # MARKER_PEERING_CONFIGURATIONS
      # example = {
      #   peerLinkLocal = "fe80";
      #   ownLinkLocal = "fe80";
      #   asNumber = "12345";
      #   # publicWireguardEndpoint = "de01.dn42.lare.cc:21403";
      #   publicWireguardKey = "xxxxx";
      #   publicWireguardPort = "5";
      # };
    };
  };
}
