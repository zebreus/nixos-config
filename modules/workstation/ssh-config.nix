{ lib, config, ... }:
let
  accessibleMachines = config.meta.accessibleMachines;
in
{
  config = lib.mkIf config.meta.self.workstation.enable {
    age.secrets.extra_config = {
      file = ../../secrets/extra_config.age;
      owner = "lennart";
      inherit (config.users.users.lennart) group;
    };

    home-manager.users = {
      lennart =
        { pkgs, ... }:
        {
          programs.ssh = {
            enable = true;
            includes = [ config.age.secrets.extra_config.path ];
            enableDefaultConfig = false; # Default values added manually below
            # The attribute name is the Host pattern; values use upstream
            # ssh_config directive names.
            settings =
              let
                # SSH entries to add all keys to the agent
                defaultForAll = {
                  "*" = {
                    ForwardAgent = false;
                    AddKeysToAgent = "yes";
                    Compression = false;
                    ServerAliveInterval = 0;
                    ServerAliveCountMax = 3;
                    HashKnownHosts = false;
                    UserKnownHostsFile = "~/.ssh/known_hosts";
                    ControlMaster = "no";
                    ControlPath = "~/.ssh/master-%r@%n:%p";
                    ControlPersist = "no";
                  };
                };
                # SSH hosts from antibuilding
                antibuildingHosts = builtins.listToAttrs (
                  builtins.map
                    (machine: {
                      name = "${machine.name} ${machine.fqdn} ${machine.antibuildingIp6}";
                      value = {
                        Port = 22;
                        User = "root";
                        HostName = machine.fqdn;
                        IdentityFile = config.age.secrets.lennart_ed25519.path;
                      };
                    })
                    accessibleMachines
                );
                # SSH hosts from cccda
                cccDaHosts = {
                  "lounge lounge.cccda.de" = {
                    HostName = "lounge.cccda.de";
                    User = "chaos";
                    IdentityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  "kitchen kitchen.cccda.de" = {
                    HostName = "kitchen.cccda.de";
                    User = "chaos";
                    IdentityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  "workshop workshop.cccda.de" = {
                    HostName = "workshop.cccda.de";
                    User = "chaos";
                    IdentityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  "door door.cccda.de" = {
                    HostName = "door.cccda.de";
                    User = "door";
                    IdentityFile = config.age.secrets.w17_door_ed25519.path;
                  };
                };
                # Code forges
                forges = {
                  "github.com" = {
                    User = "git";
                    IdentityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  "gitlab.com" = {
                    User = "git";
                    IdentityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  "aur.archlinux.org" = {
                    User = "aur";
                    IdentityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  "ssh.gitlab.gnome.org gitlab.gnome.org" = {
                    HostName = "ssh.gitlab.gnome.org";
                    User = "git";
                    IdentityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  "gitea.com" = {
                    User = "git";
                    IdentityFile = config.age.secrets.lennart_ed25519.path;
                    # gitea.com (a Go SSH server) only offers an RSA host key, so the
                    # global ssh-ed25519-only hostKeyAlgorithms restriction breaks it.
                    # Re-enable the SHA-2 RSA host key algorithms for this host only.
                    HostKeyAlgorithms = "ssh-ed25519,rsa-sha2-512,rsa-sha2-256";
                  };
                  "codeberg.org" = {
                    User = "git";
                    IdentityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  "git.code.sf.net code.sf.net sourceforge" = {
                    HostName = "git.code.sf.net";
                    User = "zebreus";
                    IdentityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  "bitbucket.org" = {
                    User = "git";
                    IdentityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  "review.coreboot.org" = {
                    User = "zebreus";
                    Port = 29418;
                    IdentityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  "git.transgirl.cafe" = {
                    User = "git";
                    IdentityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  "git.darmstadt.ccc.de" = {
                    User = "git";
                    IdentityFile = config.age.secrets.lennart_ed25519.path;
                  };
                };
                # Miscellaneous hosts
                miscHosts = {
                  # Ubuntu VM running on glouble. Contains some stuff that doesn't run on nix.
                  "ubuntu-vm" = {
                    HostName = "192.168.135.2";
                    User = "root";
                    ProxyJump = "root@glouble";
                    IdentityFile = config.age.secrets.lennart_ed25519.path;
                  };
                };
              in
              antibuildingHosts // cccDaHosts // forges // miscHosts // defaultForAll;
          };
        };
    };
  };
}
