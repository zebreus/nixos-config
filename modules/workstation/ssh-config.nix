{ lib, config, ... }:
let
  accessibleMachines = lib.attrValues (
    (lib.filterAttrs (name: machine: machine.sshPublicKey != null)) config.machines
  );
in
{
  config = lib.mkIf config.machines.${config.networking.hostName}.workstation.enable {
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
            addKeysToAgent = "yes";
            matchBlocks =
              let
                # SSH hosts from antibuilding
                antibuildingHosts = builtins.listToAttrs (
                  builtins.map
                    (machine: {
                      inherit (machine) name;
                      value = {
                        port = 22;
                        user = "root";
                        hostname = "${machine.name}.antibuild.ing";
                        host = ''${machine.name} ${machine.name}.antibuild.ing ${config.antibuilding.ipv6Prefix}::${builtins.toString machine.address}'';
                        identityFile = config.age.secrets.lennart_ed25519.path;
                      };
                    })
                    accessibleMachines
                );
                # SSH hosts from university
                hdaHosts = {
                  hdaGitlab = {
                    host = "code.fbi.h-da.de";
                    identityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  gsiLogin = {
                    host = "gsi-login lx-pool.gsi.de";
                    hostname = "lx-pool.gsi.de";
                    user = "leichhor";
                    identityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  gsiSubmit = {
                    proxyJump = "gsi-login";
                    host = "gsi-submit vae22.hpc.gsi.de";
                    hostname = "vae22.hpc.gsi.de";
                    user = "leichhor";
                    identityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  gsiVirgo = {
                    proxyJump = "gsi-login";
                    host = "gsi-virgo virgo.hpc.gsi.de";
                    hostname = "virgo.hpc.gsi.de";
                    user = "leichhor";
                    identityFile = config.age.secrets.lennart_ed25519.path;
                  };
                };
                # SSH hosts from cccda
                cccDaHosts = {
                  lounge = {
                    host = "lounge lounge.cccda.de";
                    hostname = "lounge.cccda.de";
                    user = "chaos";
                    identityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  kitchen = {
                    host = "kitchen kitchen.cccda.de";
                    hostname = "kitchen.cccda.de";
                    user = "chaos";
                    identityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  workshop = {
                    host = "workshop workshop.cccda.de";
                    hostname = "workshop.cccda.de";
                    user = "chaos";
                    identityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  door = {
                    host = "door door.cccda.de";
                    hostname = "door.cccda.de";
                    user = "door";
                    identityFile = config.age.secrets.w17_door_ed25519.path;
                  };
                };
                # Code forges
                forges = {
                  githubCom = {
                    hostname = "github.com";
                    host = "github.com";
                    user = "git";
                    identityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  gitlabCom = {
                    hostname = "gitlab.com";
                    host = "gitlab.com";
                    user = "git";
                    identityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  aur = {
                    hostname = "aur.archlinux.org";
                    host = "aur.archlinux.org";
                    user = "aur";
                    identityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  gnomeGitlab = {
                    hostname = "ssh.gitlab.gnome.org";
                    host = "ssh.gitlab.gnome.org gitlab.gnome.org";
                    user = "git";
                    identityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  gitea = {
                    hostname = "gitea.com";
                    host = "gitea.com";
                    user = "git";
                    identityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  codeberg = {
                    hostname = "codeberg.org";
                    host = "codeberg.org";
                    user = "git";
                    identityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  sourceForge = {
                    hostname = "git.code.sf.net";
                    host = "git.code.sf.net code.sf.net sourceforge";
                    user = "zebreus";
                    identityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  bitbucket = {
                    hostname = "bitbucket.org";
                    host = "bitbucket.org";
                    user = "git";
                    identityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  corebootGerrit = {
                    hostname = "review.coreboot.org";
                    host = "review.coreboot.org";
                    user = "zebreus";
                    port = 29418;
                    identityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  tgc = {
                    hostname = "git.transgirl.cafe";
                    host = "git.transgirl.cafe";
                    user = "git";
                    identityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  gitDarmstadtCcc = {
                    hostname = "git.darmstadt.ccc.de";
                    host = "git.darmstadt.ccc.de";
                    user = "git";
                    identityFile = config.age.secrets.lennart_ed25519.path;
                  };
                };
                # Miscellaneous hosts
                miscHosts = {
                  # Strato server. Cancelled for 07.09.2024 because I don't need it anymore.
                  # Currently runs a tor bridge
                  stratoAlpha = {
                    host = "h2903394.stratoserver.net h2903394 85.214.55.42";
                    hostname = "85.214.55.42";
                    user = "root";
                    identityFile = config.age.secrets.lennart_ed25519.path;
                  };
                  # Strato server. Cancelled for 07.09.2024 because I don't need it anymore.
                  # Currently runs a tor relay
                  stratoBeta = {
                    host = "h2903395.stratoserver.net h2903395 85.214.52.114";
                    hostname = "85.214.52.114";
                    user = "root";
                    identityFile = config.age.secrets.lennart_ed25519.path;
                  };
                };
              in
              antibuildingHosts // hdaHosts // cccDaHosts // forges // miscHosts;
          };
        };
    };
  };
}
