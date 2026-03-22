{ lib, pkgs, ... }: {
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    # ./ubuntu-vm.nix
    ../../modules
  ];

  system.stateVersion = "25.11";
  networking.hostName = "glouble";

  # Allow nested virtualization
  boot = {
    extraModprobeConfig = ''
      options kvm_intel nested=1
    '';
  };

  # networkd
  networking.useNetworkd = true;
  systemd.network.networks.enp3s0 = {
    # TODO: A lot of these settings are probably not necessary, but whatever, they work 
    matchConfig = {
      MACAddress = "a8:b8:e0:08:05:dc";
    };
    networkConfig = {
      DHCP = "ipv4";
      IPv6AcceptRA = true; # Accept router advertisments to find the gateway and stuff
      IPv6PrivacyExtensions = false; # Don't generate a privacy address
    };
    ipv6AcceptRAConfig = {
      UseAutonomousPrefix = true;
      UseOnLinkPrefix = false;
      Token = "static:::beef:face";
    };
    dhcpV4Config = {
      UseDNS = true;
    };
    dhcpV6Config = {
      UseAddress = false;
    };
  };

  # Networking for shitty vodafone router
  # networking.useNetworkd = true;
  # systemd.network.networks.enp3s0 = {
  #   matchConfig = {
  #     MACAddress = "a8:b8:e0:08:05:dc";
  #   };
  #   networkConfig = {
  #     DHCP = "ipv4";
  #     IPv6AcceptRA = true; # Accept router advertisments to find the gateway and stuff
  #     IPv6PrivacyExtensions = false; # Don't generate a privacy address
  #   };
  #   ipv6AcceptRAConfig = {
  #     UseAutonomousPrefix = false;
  #     UseOnLinkPrefix = false;
  #   };
  #   dhcpV4Config = {
  #     DUIDType = "vendor";
  #     DUIDRawData = "00:00:ca:fe:ca:fe:ca:fe:ca:fe:ca:fe";
  #   };
  #   dhcpV6Config = {
  #     UseAddress = true;
  #     DUIDType = "vendor";
  #     DUIDRawData = "00:00:ca:fe:ca:fe:ca:fe:ca:fe:ca:fe";
  #   };
  # };


  environment.systemPackages = with pkgs; [
    # For debugging and stuff
    hdparm
    nvme-cli
    sysstat
  ];

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
  boot.supportedFilesystems.bcachefs = lib.mkForce true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # Spin down hard drives after 10 minutes of inactivity
  systemd.services.hd-idle = {
    enable = true;
    description = "Suspend idle hard drives";

    after = [ "systemd-modules-load.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Nice = 19;
      Restart = "always";
      Type = "simple";
      RestartSec = "30s";
      ExecStart =
        let
          ataDrives = [
            "/dev/disk/by-id/ata-OOS14000G_000AB2EC"
            "/dev/disk/by-id/ata-OOS14000G_000AEPBK"
            "/dev/disk/by-id/ata-OOS14000G_000EMSFT"
            "/dev/disk/by-id/ata-OOS14000G_000B0BLM"
          ];
          scsiDrives = [
            "/dev/disk/by-id/ata-WDC_WD140EDGZ-11B1PA0_7LGJ8SEK"
            "/dev/disk/by-id/ata-WDC_WD140EDGZ-11B1PA0_7LGJAD7K"
          ];
          suspendAfterSeconds = 60 * 10;
        in
        "${lib.getExe pkgs.hd-idle} -i 0 -s 1 ${lib.concatStringsSep " " (map (d: "-a " + d + " -c ata -i " + (builtins.toString suspendAfterSeconds)) ataDrives)} ${lib.concatStringsSep " " (map (d: "-a " + d + " -c scsi -i " + (builtins.toString suspendAfterSeconds)) scsiDrives)}";
      User = "root";
      Group = "root";
    };
  };

  boot.initrd.systemd.enable = true;

  # # Not sure if this is still necessary
  # fileSystems."/" = {
  #   fsType = "bcachefs";
  #   options = [
  #     "x-systemd.wants=/dev/disk/by-id/nvme-eui.0025385751a00c5d"
  #     # "x-systemd.wants=/dev/disk/by-id/nvme-nvme.1e4b-465853383830323530383135313137-46616e7869616e67205338383020345442-00000001"
  #     "x-systemd.wants=/dev/disk/by-id/ata-OOS14000G_000AB2EC"
  #     "x-systemd.wants=/dev/disk/by-id/ata-OOS14000G_000AEPBK"
  #     "x-systemd.wants=/dev/disk/by-id/ata-OOS14000G_000EMSFT"
  #     "x-systemd.wants=/dev/disk/by-id/ata-OOS14000G_000B0BLM"
  #     "x-systemd.wants=/dev/disk/by-id/ata-WDC_WD140EDGZ-11B1PA0_7LGJ8SEK"
  #     "x-systemd.wants=/dev/disk/by-id/ata-WDC_WD140EDGZ-11B1PA0_7LGJAD7K"
  #     # "x-systemd.wants=/dev/sda1"
  #     # "x-systemd.wants=/dev/sdb1"
  #     # "x-systemd.wants=/dev/sdc1"
  #     # "x-systemd.wants=/dev/sdd1"
  #   ];
  # };
  systemd.enableEmergencyMode = true;
  boot.initrd.systemd.emergencyAccess = true;

  # boot.initrd.postDeviceCommands = "sleep 10";
  # boot.initrd.preDeviceCommands = "sleep 5";

  services.autotierfs = {
    enable = true;
    settings = {
      "/storage/autotier" = {
        Global = {
          "Log Level" = 2;
          "Tier Period" = 60 * 30;
          "Copy Buffer Size" = "512MiB";
          "Strict Period" = "true";
          "Metadata Path" = "/storage/autotier-meta";
        };
        "Tier 0" = {
          Path = "/storage/tier0";
          Quota = "200G";
        };
        "Tier 1" = {
          Path = "/storage/tier1";
          Quota = "20T";
        };
        "Tier 2" = {
          Path = "/storage/tier2";
          Quota = "20T";
        };
      };
    };
  };
}
