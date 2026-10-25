# Authoritative DNS servers (at least one), with a per-host name (ns1/ns2/…)
# and a single primary (responsible for DNSSEC signing).
import ../../helpers/meta-service.nix "dns" ({ config, lib, ... }: {
  cardinality = "atLeastOne";
  perHost = true;
  config.name = lib.mkOption {
    type = lib.types.str;
    example = "ns1";
    description = "Name of this DNS server. Should be like ns1, ns2, ns3, …";
  };
  extraServiceOptions.primary = lib.mkOption {
    type = lib.types.enum (builtins.attrNames config.meta.services.dns.hosts);
    description = ''
      The single primary authoritative DNS server. This one is responsible for DNSSEC signing.
    '';
  };
  projectedOptions = {
    primary = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      description = "Whether this machine is the primary authoritative DNS server.";
    };
    secondary = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      description = "Whether this machine is a secondary authoritative DNS server. Secondaries get all their zones from the primary.";
    };
  };
  projectExtra = svcCfg: h: assigned: {
    primary = svcCfg.primary == h;
    secondary = assigned && (svcCfg.primary != h);
  };
})
