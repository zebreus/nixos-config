# Meta options for the fleet.
#
# Two parts (see GLOSSARY.md):
#   * meta.machines.<host> — a machine's record: its topology / per-machine knobs,
#     plus the read-only *projection* of every meta service onto that machine.
#   * meta.services.<svc>  — a meta service: its config and a host-assignment field
#     whose type encodes the service's cardinality, so illegal assignments (two mail
#     servers, an unassigned required service, …) are unrepresentable.
#
# Each meta service is projected into every machine as
# `meta.machines.<host>.<svc>.{enable, …config}`, derived once from the assignment,
# so consumer modules keep reading `cfg.enable` + config.
{ lib, config, ... }:
with lib;
let
  backupRepoOpts = _self: {
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

  # Machine *names* are fixed by the meta config (machines.nix) and do not depend
  # on any service, so deriving them here is recursion-safe.
  hostNames = builtins.attrNames config.meta.machines;
  hostEnum = filter: types.enum (if filter == null then hostNames else filter hostNames);

  # Hosts reachable from the public internet (both static IPs set). Used as a
  # dependent enum so a service that needs global reachability can only be
  # assigned to a qualifying host — this replaces the old hand-rolled static-IP
  # assertions for monitoring / bird-lg.
  hostsWithStaticIps = builtins.filter
    (h: let m = config.meta.machines.${h}; in m.staticIp4 != null && m.staticIp6 != null)
    hostNames;

  # ─── Service definitions: the single source of truth ───────────────────────
  # Each entry declares a service's cardinality and config schema. Flat services
  # share their config across every assigned machine; perHost services carry
  # per-host config keyed by host name.
  serviceDefs = {
    mail = {
      cardinality = "atMostOne";
      config.baseDomain = mkOption {
        type = types.str;
        description = ''
          Base domain for the mail server. You need to setup the DNS records according to the
          setup guide at https://nixos-mailserver.readthedocs.io/en/latest/setup-guide.html
          and https://nixos-mailserver.readthedocs.io/en/latest/autodiscovery.html. Also add
          an additional SPF record for the mail subdomain.
        '';
      };
    };

    matrix = {
      cardinality = "atMostOne";
      config.baseDomain = mkOption {
        type = types.str;
        description = "Base domain for the matrix server.";
      };
    };

    matrixLite = {
      cardinality = "atMostOne";
      config.baseDomain = mkOption {
        type = types.str;
        description = "Base domain for the matrix-lite server.";
      };
    };

    event = {
      cardinality = "atMostOne";
      config.baseDomain = mkOption {
        type = types.str;
        description = "Base domain for the event.";
      };
    };

    n50camp = {
      cardinality = "atMostOne";
      config = {
        # All base domains the event is reachable under. Every HTTP service is
        # served on all of these; services that cannot serve multiple domains are
        # served on primaryBaseDomain and the secondaries redirect to it.
        baseDomains = mkOption {
          type = types.listOf types.str;
          description = "Base domains for the N50 camp event.";
        };
        primaryBaseDomain = mkOption {
          type = types.str;
          description = "Canonical base domain for the N50 camp event. Secondaries redirect here for services that cannot serve multiple domains.";
        };
      };
    };

    besserestrichliste = {
      cardinality = "atMostOne";
      config = {
        baseDomain = mkOption {
          type = types.str;
          default = "wirs.ing";
          description = "Base domain for the besserestrichliste server";
        };
        subDomain = mkOption {
          type = types.str;
          default = "besserer";
          description = "Subdomain for the besserestrichliste server";
        };
      };
    };

    rudelshopping = {
      cardinality = "atMostOne";
      config = {
        baseDomain = mkOption {
          type = types.str;
          default = "rudelb.link";
          description = "Base domain for the rudelshopping server";
        };
        subDomain = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Subdomain for the rudelshopping server. When null the service runs
            on the apex of baseDomain.
          '';
        };
      };
    };

    essenJetzt.cardinality = "atMostOne";
    photos.cardinality = "atMostOne";
    homeassistant.cardinality = "atMostOne";

    suckmoreOrg = {
      cardinality = "atMostOne";
      config = {
        enableCaching = mkOption {
          type = types.bool;
          default = true;
          description = "Enable aggressive caching for suckmore.org. This is not recommended if you are actively developing on the server, because you might not see your changes immediately.";
        };
        baseDomain = mkOption {
          type = types.str;
          default = "suckmore.org";
          description = "Base domain for the suckmore.org server.";
        };
      };
    };

    gulaschSites = {
      cardinality = "atMostOne";
      config.baseDomain = mkOption {
        type = types.str;
        default = "gulasch.site";
        description = "Base domain for the exported static gulasch sites.";
      };
    };

    # Run grafana and the prometheus collector. Needs global reachability.
    monitoring = {
      cardinality = "exactlyOne";
      hostFilter = _: hostsWithStaticIps;
    };

    # bird-lg looking-glass frontend. Needs global reachability.
    bird-lg = {
      cardinality = "exactlyOne";
      hostFilter = _: hostsWithStaticIps;
    };

    # Any number of ollama hosts; the accelerator (package) is a per-machine knob.
    ollama.cardinality = "any";

    # Backup hosts, with per-host storage location.
    backup = {
      cardinality = "any";
      perHost = true;
      config.storagePath = mkOption {
        type = types.str;
        example = "/backups/lennart";
        description = "The prefix of the path to the backup repos. This should be a path on a separate disk.";
      };
      projectedOptions.locationPrefix = mkOption {
        type = types.str;
        readOnly = true;
        example = "ssh://borg@janek-backup//backups/lennart/";
        description = "The prefix of the borg repo URL on this backup host (this string suffixed with the repo name is the full path to the borg repo).";
      };
      projectExtra = svcCfg: h: assigned: optionalAttrs assigned {
        locationPrefix = "ssh://borg@${h}/${svcCfg.hosts.${h}.storagePath}/";
      };
    };

    # Authoritative DNS servers (at least one), with a per-host name (ns1/ns2/…)
    # and a single primary (responsible for DNSSEC signing).
    dns = {
      cardinality = "atLeastOne";
      perHost = true;
      config.name = mkOption {
        type = types.str;
        example = "ns1";
        description = "Name of this DNS server. Should be like ns1, ns2, ns3, …";
      };
      extraServiceOptions.primary = mkOption {
        type = types.enum (builtins.attrNames config.meta.services.dns.hosts);
        description = ''
          The single primary authoritative DNS server. This one is responsible for DNSSEC signing.
        '';
      };
      projectedOptions = {
        primary = mkOption {
          type = types.bool;
          readOnly = true;
          description = "Whether this machine is the primary authoritative DNS server.";
        };
        secondary = mkOption {
          type = types.bool;
          readOnly = true;
          description = "Whether this machine is a secondary authoritative DNS server. Secondaries get all their zones from the primary.";
        };
      };
      projectExtra = svcCfg: h: assigned: {
        primary = svcCfg.primary == h;
        secondary = assigned && (svcCfg.primary != h);
      };
    };
  };

  isPerHost = def: def.perHost or false;

  # ─── Cardinality → the host-assignment field on meta.services.<svc> ─────────
  mkHostField = cardinality: filter:
    if cardinality == "exactlyOne" then {
      host = mkOption {
        type = hostEnum filter;
        description = "The machine that runs this service.";
      };
    }
    else if cardinality == "atMostOne" then {
      host = mkOption {
        type = types.nullOr (hostEnum filter);
        default = null;
        description = "The machine that runs this service, or null if it runs nowhere.";
      };
    }
    else if cardinality == "atLeastOne" then {
      hosts = mkOption {
        type = types.nonEmptyListOf (hostEnum filter);
        description = "The machines that run this service (at least one).";
      };
    }
    else if cardinality == "any" then {
      hosts = mkOption {
        type = types.listOf (hostEnum filter);
        default = [ ];
        description = "The machines that run this service (any number).";
      };
    }
    else { }; # none — config-only, no host field

  isFlatAssigned = cardinality: svcCfg: h:
    if cardinality == "exactlyOne" || cardinality == "atMostOne" then svcCfg.host == h
    else if cardinality == "atLeastOne" || cardinality == "any" then builtins.elem h svcCfg.hosts
    else false; # none

  # ─── meta.services.<svc> option ────────────────────────────────────────────
  mkServiceOption = name: def:
    let
      serviceOpts =
        if isPerHost def then
          {
            hosts =
              if def.cardinality == "any" then
                mkOption
                  {
                    type = types.attrsOf (types.submodule { options = def.config or { }; });
                    default = { };
                    description = "Per-host assignment and config for ${name} (any number).";
                  }
              else
                mkOption {
                  type = types.attrsOf (types.submodule { options = def.config or { }; });
                  description = "Per-host assignment and config for ${name} (at least one).";
                };
          } // (def.extraServiceOptions or { })
        else
          (mkHostField def.cardinality (def.hostFilter or null))
          // (def.config or { })
          // (def.extraServiceOptions or { });
    in
    mkOption {
      type = types.submodule { options = serviceOpts; };
      default = { };
      description = "Meta service: ${name}.";
    };

  # ─── Read-only projection of a service onto a machine ──────────────────────
  mkProjectedOptions = name: def:
    {
      enable = mkOption {
        type = types.bool;
        readOnly = true;
        description = "Whether ${name} runs on this machine.";
      };
    }
    # Strip the default: the projection always assigns the value explicitly, and
    # a readOnly option with both a default (a low-priority definition) and an
    # explicit definition would trip the "set multiple times" check.
    // (mapAttrs (_n: o: (builtins.removeAttrs o [ "default" "defaultText" ]) // { readOnly = true; }) (def.config or { }))
    // (def.projectedOptions or { });

  projectService = name: def: h:
    let
      svcCfg = config.meta.services.${name};
      assigned =
        if isPerHost def then builtins.hasAttr h svcCfg.hosts
        else isFlatAssigned def.cardinality svcCfg h;
      # intersectAttrs keeps only the declared config-field keys, dropping the
      # host field and any submodule-internal attrs (e.g. _module).
      #
      # Flat services share their config, so it is projected onto *every* machine
      # (never null). A perHost service's config is per-host, so on an UNASSIGNED
      # machine its projected config fields (e.g. backup.storagePath /
      # backup.locationPrefix, dns.name) are left *undefined* — reading them
      # ungated throws "option used but not defined". This is intentional;
      # consumers must scope reads to the assigned set (attrNames
      # meta.services.<svc>.hosts / meta.allBackupHosts) or gate on `.enable`.
      configFields =
        if isPerHost def
        then (if assigned then builtins.intersectAttrs (def.config or { }) svcCfg.hosts.${h} else { })
        else builtins.intersectAttrs (def.config or { }) svcCfg;
      extra = (def.projectExtra or (_svcCfg: _h: _assigned: { })) svcCfg h assigned;
    in
    { enable = assigned; } // configFields // extra;

  projectedServiceOptions = foldl' recursiveUpdate { }
    (mapAttrsToList (name: def: { ${name} = mkProjectedOptions name def; }) serviceDefs);

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

    extraBorgRepos = mkOption {
      type = types.listOf (types.submodule backupRepoOpts);
      description = ''
        Extra borg repos used by this machine.
      '';
      default = [ ];
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

    # The accelerator depends on the machine's hardware, so it is a per-machine
    # knob even though the ollama *assignment* is a service.
    ollama.package = mkOption {
      type = types.str;
      description = "Select the accelerator. See services.ollama.acceleration for details";
      default = "rocm";
    };

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

  machineOpts = self: {
    # ollama carries both a per-machine knob (package) and a projected service
    # field (enable), so the two option trees are deep-merged.
    options = recursiveUpdate (perMachineOptions self) projectedServiceOptions;

    config = listToAttrs (mapAttrsToList
      (name: def: nameValuePair name (projectService name def self.config.name))
      serviceDefs);
  };
in
{
  options.meta = {
    machines = mkOption {
      default = { };
      description = "Information about the machines in the network";
      type = types.attrsOf (types.submodule machineOpts);
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

    services = mapAttrs mkServiceOption serviceDefs;

    allBorgRepos = mkOption {
      type = types.listOf (types.submodule backupRepoOpts);
      description = ''
        All borg repos that will be generated on the backup hosts. The meta
        module contributes one per machine extraBorgRepos entry and one home repo
        per workstation; service modules (mail, matrix, …) add their own.
      '';
      default = [ ];
    };

    allBackupHosts = mkOption {
      # Raw, to avoid re-coercing already-evaluated machine records (which carry
      # readOnly projected options) back through the machine submodule.
      type = types.listOf types.raw;
      readOnly = true;
      description = "All machines that are backup hosts. Derived from meta.services.backup.";
      default = attrValues (filterAttrs (_name: m: m.backup.enable) config.meta.machines);
    };
  };

  # The bulk of the borg repos: one per machine extraBorgRepos entry and a home
  # repo for every workstation. Service modules merge in their own repos.
  config.meta.allBorgRepos =
    (builtins.concatMap (m: m.extraBorgRepos) (attrValues config.meta.machines))
    ++ (builtins.concatMap
      (m: optional m.workstation.enable { name = "lennart_${m.name}"; size = "3T"; })
      (attrValues config.meta.machines));

  # Host references in per-host services are attrset keys, which attrsOf does not
  # validate — so a typo'd host would silently no-op. Catch that here.
  config.assertions =
    (mapAttrsToList
      (name: _def:
        let
          hosts = config.meta.services.${name}.hosts;
          badKeys = builtins.filter (k: !(builtins.elem k hostNames)) (builtins.attrNames hosts);
        in
        {
          assertion = badKeys == [ ];
          message = "meta.services.${name}.hosts references unknown machine(s): ${concatStringsSep ", " badKeys}. Valid machines: ${concatStringsSep ", " hostNames}.";
        })
      (filterAttrs (_name: isPerHost) serviceDefs))
    ++ (mapAttrsToList
      (name: _def: {
        assertion = config.meta.services.${name}.hosts != { };
        message = "meta.services.${name} requires at least one host.";
      })
      (filterAttrs (_name: d: isPerHost d && d.cardinality == "atLeastOne") serviceDefs));
}
