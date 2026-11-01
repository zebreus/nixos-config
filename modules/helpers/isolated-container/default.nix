# Isolated containers: a NixOS system per service, booted with systemd as PID 1
# inside gVisor, a user-space kernel. A compromised service gets the sandbox,
# not the host kernel. Like `containers.<name>`, but opinionated. Each file
# answers one question:
#   * ./guest.nix: what runs inside the sandbox?
#   * ./sandbox.nix: what can the sandbox see, and how does runsc run it?
#   * ./hardening.nix: what may runsc itself do on the host?
#   * ./network.nix: what can the container reach, and what can reach it?
#
# Debug a running container with
#   runsc --root /run/isolated-containers/<name>/runsc exec <name> <command>
{ config, lib, ... }:
let
  cfg = config.modules.isolatedContainers;
  inherit (import ./names.nix { inherit lib; }) interface subnet units;
in
{
  imports = [
    ./guest.nix
    ./network.nix
    ./sandbox.nix
    ./hardening.nix
  ];

  options.modules.isolatedContainers = lib.mkOption {
    default = { };
    description = "NixOS systems that each run in their own gVisor sandbox (see the top of this file).";
    type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
      options = {
        config = lib.mkOption {
          type = lib.types.deferredModule;
          description = "The container's NixOS configuration.";
        };
        address = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default = "${subnet cfg name}.2";
          description = "The container's IPv4 address. The host can reach all of its ports.";
        };
      };
    }));
  };

  config = lib.mkIf (cfg != { }) {
    assertions = lib.mapAttrsToList
      (name: _: {
        assertion = builtins.match "[a-z0-9-]{1,12}" name != null;
        message = "modules.isolatedContainers.${name}: names are 1 to 12 characters of a-z, 0-9 and -, because they end up in the interface name ${interface name}.";
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
