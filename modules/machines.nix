# Option definitions for information about the machines in the network
{ lib, ... }:
with lib;
let
  machineOpts = self: {
    options = {
      name = mkOption {
        example = "bernd";
        type = types.str;
        description = lib.mdDoc "Hostname of a machine on the network";
      };

      wireguardPublicKey = mkOption {
        example = "xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=";
        type = types.singleLineStr;
        description = lib.mdDoc "The base64 wireguard public key of the machine.";
      };

      address = mkOption {
        example = 6;
        type = lib.types.ints.between 1 255;
        description = lib.mdDoc ''The last part of the IPv4 address of the machine.'';
      };

      staticIp4 = mkOption {
        example = "10.192.122.3";
        type = types.nullOr types.str;
        description = lib.mdDoc ''A static ipv4 address where this machine can be reached.'';
        default = null;
      };
    };

  };
in
{
  options = {
    machines = mkOption {
      default = [ ];
      description = lib.mdDoc "Information about the machines in the network";
      type = with types; attrsOf (submodule machineOpts);
    };
  };
}
