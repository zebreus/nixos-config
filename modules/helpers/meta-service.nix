# Declares one meta service (see GLOSSARY.md) from its definition:
#   * meta.services.<svc> — its config and a host-assignment field whose type
#     encodes the service's cardinality, so illegal assignments (two mail servers,
#     an unassigned required service, …) are unrepresentable.
#   * meta.machines.<host>.<svc> — the read-only projection of the service onto
#     every machine, `{ enable, …config }`, derived once from the assignment, so
#     consumer modules keep reading `cfg.enable` + config.
#
# Every modules/services/<svc>/meta.nix is a call of this function:
#
#   import ../../helpers/meta-service.nix "<svc>" ({ config, lib, ... }: {
#     cardinality = "atMostOne"; # exactlyOne | atMostOne | atLeastOne | any | none
#     config = { };              # optional: the service's config options
#     hostFilter = machine: true; # optional: which machines it may be assigned to
#     perHost = true;            # optional: config is per host, keyed by host name
#     extraServiceOptions = { }; # optional: more options on meta.services.<svc>
#     projectedOptions = { };    # optional: more read-only projected options,
#     projectExtra = svcCfg: host: assigned: { }; # and their values
#   })
#
# The definition can be a plain attrset when it needs no module arguments.
svc: definition:
{ config, lib, ... }@args:
with lib;
let
  def = toFunction definition args;
  svcCfg = config.meta.services.${svc};
  isPerHost = def.perHost or false;

  # Machine *names* are fixed by the meta config (machines.nix) and do not depend
  # on any service, so deriving them here is recursion-safe.
  hostNames = builtins.attrNames config.meta.machines;
  hostEnum = types.enum (
    if def ? hostFilter
    then builtins.filter (h: def.hostFilter config.meta.machines.${h}) hostNames
    else hostNames
  );

  # ─── Cardinality → the host-assignment field on meta.services.<svc> ─────────
  hostField =
    if def.cardinality == "exactlyOne" then {
      host = mkOption {
        type = hostEnum;
        description = "The machine that runs this service.";
      };
    }
    else if def.cardinality == "atMostOne" then {
      host = mkOption {
        type = types.nullOr hostEnum;
        default = null;
        description = "The machine that runs this service, or null if it runs nowhere.";
      };
    }
    else if def.cardinality == "atLeastOne" then {
      hosts = mkOption {
        type = types.nonEmptyListOf hostEnum;
        description = "The machines that run this service (at least one).";
      };
    }
    else if def.cardinality == "any" then {
      hosts = mkOption {
        type = types.listOf hostEnum;
        default = [ ];
        description = "The machines that run this service (any number).";
      };
    }
    else { }; # none — config-only, no host field

  perHostField = {
    hosts =
      if def.cardinality == "any" then
        mkOption
          {
            type = types.attrsOf (types.submodule { options = def.config or { }; });
            default = { };
            description = "Per-host assignment and config for ${svc} (any number).";
          }
      else
        mkOption {
          type = types.attrsOf (types.submodule { options = def.config or { }; });
          description = "Per-host assignment and config for ${svc} (at least one).";
        };
  };

  isAssigned = h:
    if isPerHost then builtins.hasAttr h svcCfg.hosts
    else if def.cardinality == "exactlyOne" || def.cardinality == "atMostOne" then svcCfg.host == h
    else if def.cardinality == "atLeastOne" || def.cardinality == "any" then builtins.elem h svcCfg.hosts
    else false; # none

  # ─── Read-only projection of the service onto a machine ────────────────────
  projectedOptions =
    {
      enable = mkOption {
        type = types.bool;
        readOnly = true;
        description = "Whether ${svc} runs on this machine.";
      };
    }
    # Strip the default: the projection always assigns the value explicitly, and
    # a readOnly option with both a default (a low-priority definition) and an
    # explicit definition would trip the "set multiple times" check.
    // (mapAttrs (_n: o: (builtins.removeAttrs o [ "default" "defaultText" ]) // { readOnly = true; }) (def.config or { }))
    // (def.projectedOptions or { });

  project = h:
    let
      assigned = isAssigned h;
      # intersectAttrs keeps only the declared config-field keys, dropping the
      # host field and any submodule-internal attrs (e.g. _module).
      #
      # Flat services share their config, so it is projected onto *every* machine
      # (never null). A perHost service's config is per-host, so on an UNASSIGNED
      # machine its projected config fields (e.g. dns.name) are left *undefined* —
      # reading them ungated throws "option used but not defined". This is
      # intentional; consumers must scope reads to the assigned set (attrNames
      # meta.services.<svc>.hosts) or gate on `.enable`.
      configFields =
        if isPerHost
        then (if assigned then builtins.intersectAttrs (def.config or { }) svcCfg.hosts.${h} else { })
        else builtins.intersectAttrs (def.config or { }) svcCfg;
      extra = (def.projectExtra or (_svcCfg: _h: _assigned: { })) svcCfg h assigned;
    in
    { enable = assigned; } // configFields // extra;
in
{
  options.meta.services.${svc} = mkOption {
    type = types.submodule {
      options =
        (if isPerHost then perHostField else hostField // (def.config or { }))
        // (def.extraServiceOptions or { });
    };
    default = { };
    description = "Meta service: ${svc}.";
  };

  options.meta.machines = mkOption {
    type = types.attrsOf (types.submodule ({ name, ... }: {
      options.${svc} = projectedOptions;
      config.${svc} = project name;
    }));
  };

  # Host references in per-host services are attrset keys, which attrsOf does not
  # validate — so a typo'd host would silently no-op. Catch that here.
  config.assertions = optionals isPerHost (
    let
      badKeys = builtins.filter (k: !(builtins.elem k hostNames)) (builtins.attrNames svcCfg.hosts);
    in
    [{
      assertion = badKeys == [ ];
      message = "meta.services.${svc}.hosts references unknown machine(s): ${concatStringsSep ", " badKeys}. Valid machines: ${concatStringsSep ", " hostNames}.";
    }]
    ++ optional (def.cardinality == "atLeastOne") {
      assertion = svcCfg.hosts != { };
      message = "meta.services.${svc} requires at least one host.";
    }
  );
}
