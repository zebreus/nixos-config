{
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
}
