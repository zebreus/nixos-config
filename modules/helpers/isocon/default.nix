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
# and read its journal, also when it's stopped, with
#   journalctl -m _HOSTNAME=<name>
{ config, lib, ... }:
let
  cfg = config.isocon;
  inherit (import ./names.nix { inherit lib; }) user units;

  ports = protocol: lib.mkOption {
    type = lib.types.listOf (lib.types.submodule {
      options = {
        port = lib.mkOption {
          type = lib.types.port;
          description = "The port, in the container and on the host. For ports below 1024, the host's firewall sees 30000 + port, so open that one.";
        };
        mode = lib.mkOption {
          type = lib.types.enum [ "local" "global" ];
          default = "local";
          description = "Where the host forwards the port: local only on loopback, global on all of its addresses, which also makes it reachable from other machines if the host's firewall lets them.";
        };
        ipv4 = lib.mkEnableOption "forwarding IPv4 connections. The guest has to listen on 0.0.0.0 or ::" // { default = true; };
        # pasta can't turn IPv6 connections into IPv4 ones. Clients only try
        # another address if connecting fails, which it does if pasta doesn't
        # listen, but not if the guest resets it after pasta accepted.
        ipv6 = lib.mkEnableOption "forwarding IPv6 connections. The guest has to listen on ::, else IPv6 clients are reset instead of falling back to IPv4";
      };
    });
    default = [ ];
    example = [{ port = 8080; } { port = 8443; mode = "global"; ipv6 = true; }];
    description = "${protocol} ports of the container that the host forwards at the same port.";
  };

  outgoingPorts = protocol: default: lib.mkOption {
    type = lib.types.listOf (lib.types.coercedTo lib.types.port (port: { inherit port; }) (lib.types.submodule {
      options = {
        port = lib.mkOption {
          type = lib.types.port;
          description = "The port.";
        };
        local = lib.mkEnableOption "connections to the port on the host itself, which includes other containers";
        internal = lib.mkEnableOption "connections to the port on private addresses other than the host's, like a VPN's or a LAN's";
        global = lib.mkEnableOption "connections to the port on public addresses" // { default = true; };
      };
    }));
    inherit default;
    example = [ 443 { port = 9100; internal = true; global = false; } ];
    description = "${protocol} ports that the container may connect to. Everything else, including ping, is blocked.";
  };
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
        tcpPorts = ports "TCP";
        udpPorts = ports "UDP";
        outgoingTcpPorts = outgoingPorts "TCP" [ 53 443 ];
        outgoingUdpPorts = outgoingPorts "UDP" [ 53 ];
        persist = lib.mkOption {
          type = lib.types.listOf (lib.types.strMatching "/.+");
          default = [ ];
          example = [ "/var/lib/immich" ];
          description = "Directories of the container that survive restarts, besides /var/lib/nixos and /var/log/journal. Everything else resets.";
        };
        credentials = lib.mkOption {
          type = lib.types.attrsOf lib.types.externalPath;
          default = { };
          example = lib.literalExpression "{ stripe = config.age.secrets.stripe.path; }";
          description = "Files on the host that the guest gets as systemd credentials, by name. Its units read them with LoadCredential=<name>, or at /run/credentials/@system/<name>. The host's systemd reads the files as root, so they may be root-only.";
        };
        maxDisk = lib.mkOption {
          type = lib.types.nullOr lib.types.ints.positive;
          default = null;
          example = 100;
          description = "Disk space in GiB for all persisted directories together. Needs project quotas on the host's /var/lib (prjquota); without them, systemd silently sets no limit.";
        };
        maxCpu = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "200%";
          description = "CPU time for all of the container's processes together, as CPUQuota= takes it (100% is one CPU). The guest sees it as that many CPUs, rounded up, but at least 2.";
        };
        maxMemory = lib.mkOption {
          type = lib.types.nullOr lib.types.ints.positive;
          default = null;
          example = 4;
          description = "Memory in GiB for all of the container's processes together. This includes everything the guest doesn't persist. The guest sees it as its total memory, and each of its tmpfs (/run, /dev/shm, /tmp) and the rest of its root filesystem may fill half of it. When it runs out, the host kills the whole container, which then restarts.";
        };
      };
    });
  };

  config = lib.mkIf (cfg != { }) {
    assertions = lib.mapAttrsToList
      (name: _: {
        assertion = builtins.match "[a-z0-9-]+" name != null;
        message = "isocon.${name}: names consist of a-z, 0-9 and -, because they end up in user and unit names like ${user name}.";
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
