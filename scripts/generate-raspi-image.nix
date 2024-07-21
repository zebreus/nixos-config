# Generate a sd card image for the raspi 4
{ pkgs }:
with pkgs; writeScriptBin "generate-raspi-installer" ''
  #!${bash}/bin/bash
  RESULT_PATH=$(nix build .#nixosConfigurations.kappril.config.system.build.sdImage --print-out-paths)
  echo $RESULT_PATH
  ln -s $RESULT_PATH/sd-image/*.img.zst ./raspi-image.img.zst
  echo The generated image was linked to ./raspi-image.img.zst
  echo Dont forget to place the age key on the image after writing it to the sd card
''
