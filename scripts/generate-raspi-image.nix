# Generate a sd card image for a raspi 4 host
{ pkgs }:
with pkgs; writeScriptBin "generate-raspi-installer" ''
  #!${bash}/bin/bash
  HOST=$1
  if [ -z "$HOST" ]; then
    echo "Usage: generate-raspi-installer <host>"
    echo "HOST must be a nixosConfiguration with modules.boot.type = \"raspi\""
    exit 1
  fi
  RESULT_PATH=$(nix build .#nixosConfigurations."$HOST".config.system.build.sdImage --print-out-paths)
  echo $RESULT_PATH
  ln -s $RESULT_PATH/sd-image/*.img.zst ./raspi-image.img.zst
  echo The generated image was linked to ./raspi-image.img.zst
  echo Dont forget to place the age key on the image after writing it to the sd card
''
