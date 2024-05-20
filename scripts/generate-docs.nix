# Generate documentation for the options defined in this flake.
{ pkgs, lib, ... }:
let
  optionsDoc = pkgs.nixosOptionsDoc {
    inherit ((lib.evalModules {
      modules = [
        {
          config = {
            _module.check = false;
          };
          options.services.borgbackup.jobs = lib.mkOption { description = "Normal borg backup jobs."; };
        }
        ../modules/helpers/machines.nix
        ../modules
      ];

    })) options;

    transformOptions = opt: opt // {
      # Clean up declaration sites to not refer to the NixOS source tree.
      declarations = map
        (decl:
          let subpath = lib.removePrefix "/" (lib.removePrefix (toString ./.) (toString decl));
          in { url = subpath; name = subpath; })
        opt.declarations;
    };
  };
in
pkgs.writeScriptBin "generate-docs" ''
  #!${pkgs.bash}/bin/bash
  cp ${optionsDoc.optionsCommonMark} ./options.md
  chmod 644 ./options.md
''
