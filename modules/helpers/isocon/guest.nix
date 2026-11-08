# What runs inside the sandbox: the container's NixOS system, with the defaults
# it needs under gVisor. ./sandbox.nix boots `toplevel`.
{ config, lib, pkgs, modulesPath, extraModules, ... }:
let
  hostStateVersion = config.system.stateVersion;
  inherit (import ./names.nix { inherit lib; }) machineId;

  guestDefaults = name: { lib, ... }: {
    nixpkgs.pkgs = pkgs;
    boot.isContainer = true;
    networking = {
      hostName = name;
      # eth0 is pasta's tap device (./network.nix); gVisor takes its address from there.
      useDHCP = false;
      nameservers = lib.mkDefault [ "1.1.1.1" "9.9.9.9" ];
      # gVisor has no netfilter, and the host firewall restricts the container.
      firewall.enable = false;
    };
    # No setuid binaries in the guest. gVisor also lacks the keyring calls that
    # run-wrappers.mount needs.
    security.enableWrappers = false;
    # gVisor's /proc/sys is read-only.
    systemd.suppressedSystemUnits = [ "systemd-sysctl.service" ];
    # gVisor rejects seccomp filters whose action kills the process, which is
    # what SystemCallFilter= does by default. Blocked calls fail with EPERM instead.
    systemd.packages = [
      (pkgs.writeTextDir "lib/systemd/system/service.d/gvisor-seccomp.conf" ''
        [Service]
        SystemCallErrorNumber=EPERM
      '')
    ];
    # /etc resets on every start.
    environment.etc.machine-id.text = "${machineId name}\n";
    # A smaller closure means fewer bind mounts.
    nix.enable = false;
    documentation.enable = false;
    system.stateVersion = lib.mkDefault hostStateVersion;
  };
in
{
  options.isocon = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({ name, config, ... }: {
      options.toplevel = lib.mkOption {
        type = lib.types.package;
        internal = true;
        readOnly = true;
        description = "The container's NixOS system.";
        default = (import "${modulesPath}/../lib/eval-config.nix" {
          system = null;
          inherit extraModules;
          modules = [ (guestDefaults name) config.config ];
        }).config.system.build.toplevel;
      };
    }));
  };
}
