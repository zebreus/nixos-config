# Generate a sd card image for the raspi 4
{ pkgs }:
with pkgs; writeScriptBin "generate-installer" ''
  #!${bash}/bin/bash
  RESULT_PATH=$(nix build .#nixosConfigurations.installer.config.system.build.isoImage --print-out-paths)
  echo $RESULT_PATH
  ln -s $RESULT_PATH/iso/* ./installer.iso
''
