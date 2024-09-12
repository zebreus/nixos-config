{ pkgs, lib, ... }: {
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ./framework.nix
    ../../modules

    {
      programs.ssh.knownHosts = {
        "build1.darmstadt.ccc.de".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE/oyJPRwW3bJoWKtXSrVOiqMaKq+9yd03+N2PuCbMKv";
        "build2.darmstadt.ccc.de".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOZ7/eZLTfUD7Ejjio+8ivNFb8iyK1CD5Pq8uCDojT+z";
        "build3.darmstadt.ccc.de".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM2D/SwJf46XCoim06lOyO42JqJiTeM8UMkT4bYluJJr";
        "build4.darmstadt.ccc.de".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDu9ZsbUYaCzzZv4vn22KrKi/R9pCfOEe4aYWyLd96C1";
      };

      nix = {
        distributedBuilds = true;
        buildMachines = [{
          hostName = "build1.darmstadt.ccc.de";
          protocol = "ssh";
          sshUser = "zebreus";
          sshKey = "/var/keys/id_remotebuild";
          systems = [
            "i686-linux"
            "x86_64-linux"
          ];
          maxJobs = 4;
          speedFactor = 6;
          supportedFeatures = [
            "big-parallel"
            "kvm"
            "nixos-test"
          ];
        }
          {
            hostName = "build2.darmstadt.ccc.de";
            protocol = "ssh";
            sshUser = "zebreus";
            sshKey = "/var/keys/id_remotebuild";
            systems = [
              "i686-linux"
              "x86_64-linux"
            ];
            maxJobs = 4;
            speedFactor = 6;
            supportedFeatures = [
              "big-parallel"
              "kvm"
              "nixos-test"
            ];
          }
          {
            hostName = "build3.darmstadt.ccc.de";
            protocol = "ssh";
            sshUser = "zebreus";
            sshKey = "/var/keys/id_remotebuild";
            systems = [
              "i686-linux"
              "x86_64-linux"
            ];
            maxJobs = 4;
            speedFactor = 6;
            supportedFeatures = [
              "big-parallel"
              "kvm"
              "nixos-test"
            ];
          }
          {
            hostName = "build4.darmstadt.ccc.de";
            protocol = "ssh";
            sshUser = "zebreus";
            sshKey = "/var/keys/id_remotebuild";
            systems = [
              "i686-linux"
              "x86_64-linux"
            ];
            # this node has half the cpu of the others
            maxJobs = 2;
            speedFactor = 6;
            supportedFeatures = [
              "big-parallel"
              "kvm"
              "nixos-test"
            ];
          }];
      };
    }

  ];

  system.stateVersion = "24.11";
  networking.hostName = "prandtl";
  modules.boot.type = "secure";
  nix.settings.max-jobs = lib.mkDefault 12;


}
