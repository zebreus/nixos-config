# Option definitions for information about the machines in the network
{ lib, config, ... }:
with lib;
let
  backupRepoOpts = self: {
    options = {
      name = mkOption {
        type = types.str;
        description = ''
          The name of the backup repository. This is used to identify the backup repository on the backup host.

          You need keys for every backup repository. Use `nix run .#gen-borg-keys <this_name> <machines> lennart` to generate the keys.
        '';
      };
      size = mkOption {
        type = types.str;
        description = ''
          Limit the maximum size of the repo.
        '';
        default = "2T";
        example = "4T";
      };
    };
  };

  machineOpts = self: {
    options = {
      name = mkOption {
        example = "bernd";
        type = types.str;
        description = "Hostname of a machine on the network";
      };

      wireguardPublicKey = mkOption {
        example = "xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=";
        type = types.singleLineStr;
        description = "The base64 wireguard public key of the machine.";
      };

      address = mkOption {
        example = 6;
        type = lib.types.ints.between 1 255;
        description = ''The last byte of the antibuilding IPv4 address of the machine.'';
      };

      staticIp6 = mkOption {
        example = "1111:1111:1111:1111::1";
        type = types.nullOr types.str;
        description = ''A static ipv6 address where this machine can be reached.'';
        default = null;
      };

      staticIp4 = mkOption {
        example = "10.192.122.3";
        type = types.nullOr types.str;
        description = ''A static ipv4 address where this machine can be reached.'';
        default = null;
      };

      vpnHub = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = ''Whether this machine is the hub of the VPN.'';
        };
        staticIp4 = mkOption {
          type = types.nullOr types.str;
          description = ''A static ipv4 address where the hub can be reached.'';
          default = if self.config.vpnHub.enable then self.config.staticIp4 else null;
          readOnly = true;
        };
        staticIp6 = mkOption {
          type = types.nullOr types.str;
          description = ''A static ipv6 address where the hub can be reached.'';
          default = if self.config.vpnHub.enable then self.config.staticIp6 else null;
          readOnly = true;
        };
      };

      trusted = mkOption {
        example = true;
        type = types.bool;
        description = ''Whether this machine is allowed to access all other machines in the VPN.'';
        default = false;
      };

      trustedPorts = mkOption {
        example = true;
        type = types.listOf types.int;
        description = ''This machine is allowed to access this tcp port on all other machines in the VPN.'';
        default = [ ];
      };

      public = mkOption {
        example = true;
        type = types.bool;
        description = ''Whether this machine can be accessed by untrusted machines in the VPN.'';
        default = false;
      };

      publicPorts = mkOption {
        example = true;
        type = types.listOf types.int;
        description = ''All other machines in the VPN are allowed to access these tcp ports on this machine.'';
        default = [ ];
      };

      sshPublicKey = mkOption {
        example = "xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=";
        type = types.nullOr types.singleLineStr;
        description = "The public SSH host key of this machine. Implies that the machine can be accessed via SSH.";
        default = null;
      };

      managed = mkOption {
        example = false;
        type = types.bool;
        description = "Specify whether this machine is managed by this nixos-config";
        default = self.config.sshPublicKey != null;
      };

      authoritativeDns = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether this machine is a authoritative DNS server";
        };
        primary = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether this machine is the primary authoritative DNS server. This one is responsible for DNSSEC signing. There should be only one primary authoritative DNS server.
          '';
        };
        name = mkOption {
          type = types.nullOr types.str;
          description = "Name of this DNS server. Should be like ns1, ns2, ns3, ";
          default = null;
          example = "ns1";
        };
      };

      backupHost = {
        enable = mkOption {
          type = types.nullOr types.bool;
          description = ''
            This machine is hosting backups. The machine should provide at least 5TB of storage.
          '';
          default = false;
        };
        storagePath = mkOption {
          type = types.nullOr types.str;
          description = ''
            The prefix of the path to the backup repos. This should be a path on a separate disk.
          '';
          default = "/storage/borg";
          example = "/backups/lennart";
        };
        locationPrefix = mkOption {
          type = types.nullOr types.str;
          description = ''
            The prefix to the borg repo. This string suffixed with the repo name is the full path to the borg repo.
          '';
          default = "ssh://borg@${self.config.name}/${self.config.backupHost.storagePath}/";
          example = "ssh://borg@janek-backup//backups/lennart/";
        };
      };

      workstation = {
        enable = mkOption {
          type = types.nullOr types.bool;
          description = ''
            This machine is a workstation. It is used for daily work and should have lennart, a GUI, ssh keys and such.

            A home backup repo will be created for each workstation.
          '';
          default = false;
        };
      };

      mailServer = {
        enable = mkEnableOption "Enable the mail server";
        # TODO: Move this somewhere else
        baseDomain = mkOption {
          type = types.str;
          description = ''
            Base domain for the mail server. You need to setup the DNS records according to the
            setup guide at https://nixos-mailserver.readthedocs.io/en/latest/setup-guide.html
            and https://nixos-mailserver.readthedocs.io/en/latest/autodiscovery.html. Also add
            an additional SPF record for the mail subdomain.
          '';
        };
        # TODO: Move this somewhere else
        certEmail = mkOption {
          type = types.str;
          description = "Email address to use for Let's Encrypt certificates.";
        };
      };

      matrixServer = {
        enable = mkEnableOption "Enable matrix server";
        # TODO: Move this somewhere else
        baseDomain = mkOption {
          type = types.str;
          description = "Base domain for the matrix server. You need to setup the DNS records for this domain and for the matrix, element, and turn subdomains.";
        };
        # TODO: Move this somewhere else
        certEmail = mkOption {
          type = types.str;
          description = "Email address to use for Let's Encrypt certificates.";
        };
      };

      monitoring = {
        enable = mkEnableOption "Run grafana and the prometheus collector on this machine";
      };

      extraBorgRepos = mkOption {
        type = types.listOf (types.submodule backupRepoOpts);
        description = ''
          Extra borg repos used by this machine.
        '';
        default = [ ];
      };
    };
  };
in
{
  options = {
    machines = mkOption {
      default = [ ];
      description = "Information about the machines in the network";
      type = with types; attrsOf (submodule machineOpts);
    };
    allBorgRepos = mkOption {
      type = types.listOf (types.submodule backupRepoOpts);
      description = ''
        List of all borg repos that will get generated. This is an internal option and should only be set implicitly.

        I am sure that there is a better way to solve this.
      '';
      default = [ ];
    };
    allBackupHosts = mkOption {
      default = lib.attrValues (lib.filterAttrs (name: machine: machine.backupHost.enable) config.machines);
      description = "All hosts that are backup hosts. Collected from machines.";
      type = with types; listOf (submodule machineOpts);
      readOnly = true;
    };
  };

  imports = [
    {
      allBorgRepos = builtins.concatMap (machine: machine.extraBorgRepos) (lib.attrValues config.machines);
    }
  ];
}
