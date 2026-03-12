{ lib, pkgs, ... }: {
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
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
    matchConfig = {
      MACAddress = "a8:b8:e0:08:05:dc";
    };
    networkConfig = {
      DHCP = "ipv4";
      IPv6AcceptRA = true; # Accept router advertisments to find the gateway and stuff
      IPv6PrivacyExtensions = false; # Don't generate a privacy address
    };
    ipv6AcceptRAConfig = {
      UseAutonomousPrefix = false;
      UseOnLinkPrefix = false;
      # Token = "static:::17";
    };
    dhcpV4Config = {
      DUIDType = "vendor";
      DUIDRawData = "00:00:ca:fe:ca:fe:ca:fe:ca:fe:ca:fe";
    };
    dhcpV6Config = {
      UseAddress = true; # Don't use the /128 assigned via dhcpv6
      # PrefixDelegationHint = "2a02:8109:d480:2d00::17/128";
      # SendHostname = true;
      # Hostname = "glouble2";
      # DuidType = "link-layer-time:2000-01-01 00:00:01 UTC";
      DUIDType = "vendor";
      DUIDRawData = "00:00:ca:fe:ca:fe:ca:fe:ca:fe:ca:fe";
      # Anonymize = false;
      # WithoutRA = "solicit";
    };
  };


  environment.systemPackages = with pkgs; [
    # For debugging and stuff
    hdparm
    nvme-cli
    sysstat
  ];

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
  # boot.supportedFilesystems.zfs = lib.mkForce true;
  boot.supportedFilesystems.bcachefs = lib.mkForce true;
  # Generated with
  # head -c4 /dev/urandom | od -A none -t x4
  networking.hostId = "f608966d";

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # Shows battery charge of connected devices on supported
        # Bluetooth adapters. Defaults to 'false'.
        Experimental = true;
        # When enabled other devices can connect faster to us, however
        # the tradeoff is increased power consumption. Defaults to
        # 'false'.
        FastConnectable = true;
      };
      Policy = {
        # Enable all controllers when they are found. This includes
        # adapters present on start as well as adapters that are plugged
        # in later on. Defaults to 'true'.
        AutoEnable = true;
      };
    };
  };
  services.blueman.enable = true;

  # Spin down hard drives after 1 minute of inactivity.
  services.udev.extraRules =
    let
      mkRule = as: lib.concatStringsSep ", " as;
      mkRules = rs: lib.concatStringsSep "\n" rs;
    in
    mkRules ([
      (mkRule [
        ''ACTION=="add|change"''
        ''SUBSYSTEM=="block"''
        ''KERNEL=="sd[a-z]"''
        ''ATTR{queue/rotational}=="1"''
        ''RUN+="${pkgs.hdparm}/bin/hdparm -S 12 /dev/%k"''
      ])
    ]);

  # If this is not set to false, the boot fails
  fileSystems."/mnt/alpha" = {
    neededForBoot = lib.mkForce false;
  };
  fileSystems."/mnt/beta" = {
    neededForBoot = lib.mkForce false;
  };
  fileSystems."/mnt/gamma" = {
    neededForBoot = lib.mkForce false;
  };
  fileSystems."/mnt/delta" = {
    neededForBoot = lib.mkForce false;
  };
}
