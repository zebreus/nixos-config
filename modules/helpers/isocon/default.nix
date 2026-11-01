# isocon, isolated containers: a NixOS system per service, booted with systemd
# as PID 1 inside gVisor, a user-space kernel. A compromised service gets the
# sandbox, not the host kernel. Like `containers.<name>`, but opinionated. Each
# file answers one question:
#   * ./guest.nix: what runs inside the sandbox?
#   * ./sandbox.nix: what can the sandbox see, and how does runsc run it?
#   * ./hardening.nix: what may runsc itself do on the host?
#   * ./network.nix: what can the container reach, and what can reach it?
#
# Debug a running container with
#   runsc --root /run/isocon/<name>/runsc exec <name> <command>
{ config, lib, ... }:
let
  cfg = config.isocon;
  inherit (import ./names.nix { inherit lib; }) user units;
in
{
  imports = [
    ./guest.nix
    ./network.nix
    ./sandbox.nix
    ./hardening.nix
  ];

  options.isocon = lib.mkOption {
    default = { };
    description = "NixOS systems that each run in their own gVisor sandbox (see the top of this file).";
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        config = lib.mkOption {
          type = lib.types.deferredModule;
          description = "The container's NixOS configuration.";
        };
        ports = lib.mkOption {
          type = lib.types.listOf lib.types.port;
          default = [ ];
          description = "TCP ports of the container that the host reaches on 127.0.0.1, at the same port.";
        };
        persist = lib.mkOption {
          type = lib.types.listOf (lib.types.strMatching "/.+");
          default = [ ];
          example = [ "/var/lib/immich" ];
          description = "Directories of the container that survive restarts, besides /var/lib/nixos and /var/log/journal. Everything else resets.";
        };
        maxDisk = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "100G";
          description = "Disk space for all persisted directories together, as StateDirectoryQuota= takes it. Needs project quotas on the host's /var/lib (prjquota); without them, systemd silently sets no limit.";
        };
      };
    });
  };

  config = lib.mkIf (cfg != { }) {
    assertions = lib.mapAttrsToList
      (name: _: {
        assertion = builtins.match "[a-z0-9-]{1,12}" name != null;
        message = "isocon.${name}: names are 1 to 12 characters of a-z, 0-9 and -, because they end up in user and unit names like ${user name}.";
      })
      cfg;

    systemd.services = units cfg (name: _: {
      description = "Isolated container ${name}";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      # Also when the guest halts itself, which nothing on the host asks it to do.
      serviceConfig.Restart = "always";
    });
  };
}
