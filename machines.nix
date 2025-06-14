# This file is the main config file for all hosts
let
  publicKeys = import secrets/public-keys.nix;
in
{
  imports = [
    modules/helpers/machines.nix
  ];
  machines = {
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
      authoritativeDns.enable = true;
      authoritativeDns.name = "ns1";
      publicPorts = [ 53 ];
      trustedPorts = [ 9100 ];
      monitoring.enable = true;
      dn42Peerings = [ "zaphyra" "decade" "stephanj" "tech9_de02" "ellie" "lgcl" "aprl" "echonet" "kioubit_de2" "routedbits_de1" "adhd" "pogopeering" "sebastians" "larede01" ];
      matrixServer = {
        enable = true;
        baseDomain = "zebre.us";
        certEmail = "lennarteichhorn@googlemail.com";
      };
    };
    kappril = {
      name = "kappril";
      address = 3;
      wireguardPublicKey = publicKeys.kappril_wireguard;
      publicPorts = [ 22 ];
      sshPublicKey = publicKeys.kappril;
      backupHost = {
        enable = true;
        storagePath = "/storage/borg";
      };
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
      backupHost = {
        enable = true;
        storagePath = "/backups/lennart";
      };
    };
    sempriaq = {
      name = "sempriaq";
      address = 7;
      wireguardPublicKey = publicKeys.sempriaq_wireguard;
      sshPublicKey = publicKeys.sempriaq;
      public = true;
      authoritativeDns.enable = true;
      authoritativeDns.name = "ns3";
      publicPorts = [ 53 ];
      staticIp4 = "192.227.228.220";
    };

    blanderdash = {
      name = "blanderdash";
      address = 8;
      wireguardPublicKey = publicKeys.blanderdash_wireguard;
      sshPublicKey = publicKeys.blanderdash;
      authoritativeDns.enable = true;
      authoritativeDns.primary = true;
      authoritativeDns.name = "ns2";
      publicPorts = [ 53 ];
      trustedPorts = [ 18000 ];
      staticIp4 = "49.13.8.171";
      staticIp6 = "2a01:4f8:c013:29b1::1";
      bird-lg.enable = true;
      besserestrichlisteServer.enable = true;
      backupHost = {
        enable = true;
        storagePath = "/storage/storagebox/borg";
      };
      mailServer = {
        enable = true;
        baseDomain = "zebre.us";
        certEmail = "lennarteichhorn@googlemail.com";
      };
      essenJetztServer.enable = true;
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
      ollama.enable = true;
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
      wireguardPublicKey = publicKeys.glouble_wireguard;
      trusted = true;
      sshPublicKey = publicKeys.glouble;
    };
    # MARKER_MACHINE_CONFIGURATIONS
  };
}
