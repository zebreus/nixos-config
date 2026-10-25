# Meta options for the fleet's machines (see GLOSSARY.md).
#
#   * meta.machines.<host> — a machine's record: its topology / per-machine knobs.
#     Each meta service (modules/services/<svc>/meta.nix, built by
#     ./meta-service.nix) adds its read-only *projection* onto every machine.
#   * meta.self, meta.domain, … — fleet-wide values and derived views.
{ lib, config, ... }:
with lib;
let
  # ─── Per-machine options (topology and knobs that are not services) ─────────
  perMachineOptions = self: {
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
      type = types.ints.between 1 255;
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

    trusted = mkOption {
      example = true;
      type = types.bool;
      description = ''Whether this machine is allowed to access all other machines in the VPN.'';
      default = false;
    };

    trustedPorts = mkOption {
      example = [ 9100 ];
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
      example = [ 53 ];
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

    auto-maintenance = {
      upgrade = mkOption {
        type = types.bool;
        default = false;
        description = "Enable automatic upgrades for this machine";
      };
      cleanup = mkOption {
        type = types.bool;
        default = true;
        description = "Enable nightly store optimise, garbage collection and /tmp clearing";
      };
      cleanTmpIfThereIsLessSpaceLeft = mkOption {
        type = types.str;
        description = ''
          Clean the /tmp directory if there are less than this much KB left on the disk.
        '';
        default = "2000000";
      };
    };

    dn42Peerings = mkOption {
      type = types.listOf types.str;
      description = ''Names of the dn42 peerings that are active on this machine.'';
      default = [ ];
    };

    workstation.enable = mkOption {
      type = types.nullOr types.bool;
      description = ''
        This machine is a workstation. It is used for daily work and should have lennart, a GUI, ssh keys and such.

        A home backup repo will be created for each workstation.
      '';
      default = false;
    };

    desktop.enable = mkEnableOption "This is a machine I use interactivly regularly (laptop, desktop, etc.). Provides a GUI and such.";

    # Derived: a machine with a public endpoint (static IPv4 or IPv6) can act as
    # a VPN hub and be reached from outside. Consumers should read this instead
    # of re-deriving the `staticIp4 != null || staticIp6 != null` predicate.
    isServer = mkOption {
      type = types.bool;
      readOnly = true;
      default = self.config.staticIp4 != null || self.config.staticIp6 != null;
      defaultText = literalExpression "staticIp4 != null || staticIp6 != null";
      description = "Whether this machine has a public endpoint (static IPv4 or IPv6).";
    };

    # Derived addressing: a machine's place on the antibuilding mesh and its
    # canonical names, all computed once from .address / .name and the fleet-wide
    # meta.ipv6Prefix / meta.domain. Consumers read these instead of re-spelling
    # the prefix arithmetic and the domain on every call site.
    antibuildingIp6 = mkOption {
      type = types.str;
      readOnly = true;
      default = "${config.meta.ipv6Prefix}::${toString self.config.address}";
      defaultText = literalExpression ''"''${meta.ipv6Prefix}::''${toString address}"'';
      description = "This machine's antibuilding mesh IPv6 address.";
    };
    antibuildingIp4 = mkOption {
      type = types.str;
      readOnly = true;
      default = "${config.meta.ipv4Prefix}.${toString (self.config.address + 128)}";
      defaultText = literalExpression ''"''${meta.ipv4Prefix}.''${toString (address + 128)}"'';
      description = "This machine's antibuilding mesh IPv4 address.";
    };
    fqdn = mkOption {
      type = types.str;
      readOnly = true;
      default = "${self.config.name}.${config.meta.domain}";
      defaultText = literalExpression ''"''${name}.''${meta.domain}"'';
      description = "This machine's fully-qualified name on the fleet domain.";
    };
    outsideFqdn = mkOption {
      type = types.str;
      readOnly = true;
      default = "${self.config.name}.outside.${config.meta.domain}";
      defaultText = literalExpression ''"''${name}.outside.''${meta.domain}"'';
      description = "This machine's externally-reachable name (resolves to its static IPs).";
    };
    lgFqdn = mkOption {
      type = types.str;
      readOnly = true;
      default = "${self.config.name}.lg.${config.meta.domain}";
      defaultText = literalExpression ''"''${name}.lg.''${meta.domain}"'';
      description = "This machine's bird looking-glass name.";
    };
    reverseDnsLabel = mkOption {
      type = types.str;
      readOnly = true;
      default = concatStringsSep "." (reverseList (stringToCharacters (fixedWidthString 20 "0" (toString self.config.address))));
      defaultText = literalExpression "nibble-reversed ip6.arpa label for address";
      description = "This machine's reversed nibble label for the antibuilding ip6.arpa zone.";
    };
  };
in
{
  imports = [ ../services/meta.nix ];

  options.meta = {
    machines = mkOption {
      default = { };
      description = "Information about the machines in the network";
      type = types.attrsOf (types.submodule (self: { options = perMachineOptions self; }));
    };

    # This machine's own record. Lets a consumer read its own topology / service
    # projection (e.g. `config.meta.self.desktop.enable`) without re-spelling the
    # `config.meta.self` lookup everywhere.
    self = mkOption {
      # Raw, to avoid re-coercing the already-evaluated machine record (which
      # carries readOnly projected options) back through the machine submodule.
      type = types.raw;
      readOnly = true;
      default = config.meta.machines.${config.networking.hostName};
      defaultText = literalExpression "config.meta.machines.\${config.networking.hostName}";
      description = "This machine's record from meta.machines (selected by networking.hostName).";
    };

    # The fleet domain. Defined here once; every <host>.fqdn / outsideFqdn / lgFqdn
    # and the DNS / mail / networking.domain wiring derive from it.
    domain = mkOption {
      type = types.str;
      default = "antibuild.ing";
      description = "The domain the antibuilding fleet lives under.";
    };

    # The fleet's mesh IPv6 prefix. Defined here once; every <host>.antibuildingIp6
    # derives from it.
    ipv6Prefix = mkOption {
      type = types.str;
      default = "fd10:2030";
      description = "The IPv6 prefix for the antibuilding mesh.";
    };

    # The fleet's mesh IPv4 /27 prefix. Defined here once; every <host>.antibuildingIp4
    # derives from it (and the dn42 OWNNET subnet references it).
    ipv4Prefix = mkOption {
      type = types.str;
      default = "172.20.179";
      description = "The IPv4 /27 network prefix (sans host octet) for the antibuilding mesh.";
    };

    # Derived fleet views, so consumers stop re-deriving these subsets inline.
    others = mkOption {
      type = types.listOf types.raw;
      readOnly = true;
      default = attrValues (filterAttrs (name: _: name != config.networking.hostName) config.meta.machines);
      defaultText = literalExpression "all machines except meta.self";
      description = "Every machine except this one.";
    };
    managedMachines = mkOption {
      type = types.listOf types.raw;
      readOnly = true;
      default = attrValues (filterAttrs (_: m: m.managed) config.meta.machines);
      defaultText = literalExpression "machines with managed == true";
      description = "Machines managed by this config.";
    };
    accessibleMachines = mkOption {
      type = types.listOf types.raw;
      readOnly = true;
      default = attrValues (filterAttrs (_: m: m.sshPublicKey != null) config.meta.machines);
      defaultText = literalExpression "machines with a known SSH host key";
      description = "Machines with a known SSH host key (assumed reachable).";
    };
  };
}
