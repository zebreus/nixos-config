# This file is the main config file for all hosts.
#
# It fills in the meta options (modules/helpers/machines.nix):
#   * meta.machines.<host> — the fleet topology and per-machine knobs.
#   * meta.services.<svc>  — which host(s) run each service, plus its config.
let
  publicKeys = import secrets/public-keys.nix;
in
{
  imports = [
    modules/helpers/machines.nix
  ];

  meta.machines = {
    erms = {
      name = "erms";
      address = 1;
      wireguardPublicKey = publicKeys.erms_wireguard;
      trusted = true;
      sshPublicKey = publicKeys.erms;
      workstation.enable = true;
      desktop.enable = true;
    };
    kashenblade = {
      name = "kashenblade";
      address = 2;
      wireguardPublicKey = publicKeys.kashenblade_wireguard;
      staticIp4 = "167.235.154.30";
      staticIp6 = "2a01:4f8:c0c:d91f::1";
      sshPublicKey = publicKeys.kashenblade;
      publicPorts = [ 53 ];
      trustedPorts = [ 9100 ];
      # dn42Peerings = [ "zaphyra" "decade" "stephanj" "tech9_de02" "ellie" "lgcl" "aprl" "echonet" "kioubit_de2" "routedbits_de1" "adhd" "sebastians" "larede01" ];
    };
    kappril = {
      name = "kappril";
      address = 3;
      wireguardPublicKey = publicKeys.kappril_wireguard;
      publicPorts = [ 22 ];
      sshPublicKey = publicKeys.kappril;
    };
    # Janeks laptop
    janek = {
      name = "janek";
      address = 4;
      wireguardPublicKey = publicKeys.janek_wireguard;
      extraBorgRepos = [
        { name = "janek"; size = "2T"; }
      ];
    };
    # Janeks server
    janek-proxmox = {
      name = "janek-proxmox";
      address = 5;
      wireguardPublicKey = publicKeys.janek-proxmox_wireguard;
      extraBorgRepos = [
        { name = "janek-proxmox"; size = "3T"; }
      ];
    };
    # Janeks backup server
    janek-backup = {
      name = "janek-backup";
      address = 6;
      wireguardPublicKey = publicKeys.janek-backup_wireguard;
      public = true;
    };
    sempriaq = {
      name = "sempriaq";
      address = 7;
      wireguardPublicKey = publicKeys.sempriaq_wireguard;
      sshPublicKey = publicKeys.sempriaq;
      public = true;
      publicPorts = [ 53 ];
      staticIp4 = "192.227.228.220";
    };

    blanderdash = {
      name = "blanderdash";
      address = 8;
      wireguardPublicKey = publicKeys.blanderdash_wireguard;
      sshPublicKey = publicKeys.blanderdash;
      publicPorts = [ 53 ];
      trustedPorts = [ 18000 ];
      staticIp4 = "49.13.8.171";
      staticIp6 = "2a01:4f8:c013:29b1::1";
    };
    prandtl = {
      name = "prandtl";
      address = 9;
      wireguardPublicKey = publicKeys.prandtl_wireguard;
      trusted = true;
      sshPublicKey = publicKeys.prandtl;
      workstation.enable = true;
      desktop.enable = true;
      auto-maintenance.cleanup = false;
    };
    # Leon (friend of basilikum) laptop
    leon = {
      name = "leon";
      address = 10;
      wireguardPublicKey = publicKeys.leon_wireguard;
      extraBorgRepos = [
        { name = "leon"; size = "2T"; }
      ];
    };
    trolltop = {
      name = "trolltop";
      address = 11;
      wireguardPublicKey = publicKeys.trolltop_wireguard;
    };
    # Void's laptop
    void-mendax = {
      name = "void-mendax";
      address = 12;
      wireguardPublicKey = publicKeys.void-mendax_wireguard;
      extraBorgRepos = [
        { name = "void-mendax"; size = "2T"; }
      ];
    };
    void-hortorum = {
      name = "void-hortorum";
      address = 13;
      wireguardPublicKey = publicKeys.void-hortorum_wireguard;
      extraBorgRepos = [
        { name = "void-hortorum"; size = "2T"; }
      ];
    };
    glouble = {
      name = "glouble";
      address = 14;
      staticIp4 = "159.195.88.96";
      staticIp6 = "2a03:4000:20:19d::beef:face";
      wireguardPublicKey = publicKeys.glouble_wireguard;
      trusted = true;
      sshPublicKey = publicKeys.glouble;
    };
    # MARKER_MACHINE_CONFIGURATIONS
  };

  meta.services = {
    # Authoritative DNS: ns1 kashenblade, ns2 blanderdash (primary), ns3 sempriaq.
    dns = {
      hosts = {
        kashenblade.name = "ns1";
        blanderdash.name = "ns2";
        sempriaq.name = "ns3";
      };
      primary = "blanderdash";
    };

    monitoring.host = "kashenblade";
    bird-lg.host = "blanderdash";

    ollama.hosts = [ "prandtl" ];

    # Backup hosts and their storage locations.
    backup.hosts = {
      kappril.storagePath = "/storage/borg";
      janek-backup.storagePath = "/backups/lennart";
      # blanderdash.storagePath = "/storage/storagebox/borg";
    };

    mail = {
      host = "blanderdash";
      baseDomain = "zebre.us";
    };

    matrix = {
      host = "kashenblade";
      baseDomain = "zebre.us";
    };
    matrixLite = {
      host = "kashenblade";
      baseDomain = "wirs.ing";
    };

    event = {
      host = "blanderdash";
      baseDomain = "darmfest.de";
    };

    n50camp = {
      host = "blanderdash";
      baseDomains = [ "camp.n50.lat" "n50.camp" ];
      primaryBaseDomain = "camp.n50.lat";
    };

    # besserestrichliste.host = "blanderdash";

    rudelshopping.host = "blanderdash";

    photos.host = "blanderdash";
    essenJetzt.host = "blanderdash";
    homeassistant.host = "glouble";

    suckmoreOrg = {
      host = "blanderdash";
      enableCaching = false;
    };

    gulaschSites.host = "blanderdash";
  };
}
