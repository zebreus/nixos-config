# Any number of ollama hosts.
{ lib, ... }:
{
  imports = [ (import ../../helpers/meta-service.nix "ollama" { cardinality = "any"; }) ];

  # The accelerator depends on the machine's hardware, so it is a per-machine
  # knob even though the ollama *assignment* is a service.
  options.meta.machines = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options.ollama.package = lib.mkOption {
        type = lib.types.str;
        description = "Select the accelerator. See services.ollama.acceleration for details";
        default = "rocm";
      };
    });
  };
}
