{ pkgs }:
with pkgs; writeScriptBin "add-workstation" ''
  #!${bash}/bin/bash
  TARGET_HOSTNAME=$1
  if [ -z "$TARGET_HOSTNAME" ]; then
    echo "Usage: add-workstation <target_hostname>"
    echo "Adds a machine as a decryptor for the workstation secrets."
    exit 1
  fi

  if [ ! -f secrets.nix ]; then
    if [ ! -d secrets ]; then
      echo "You need to run this script in the directory with the agenix secrets.nix"
      exit 1
    fi

    cd secrets

    if [ ! -f secrets.nix ]; then
      echo "You need to run this script in the directory with the agenix secrets.nix2"
      exit 1
    fi
  fi

  # if grep 'workstations =' public-keys.nix | grep -q "$TARGET_HOSTNAME"; then
  #   echo "Workstations already contains the target hostname ($TARGET_HOSTNAME)."
  #   exit 1
  # fi

  if ! grep 'workstations =' public-keys.nix | grep -q "$(cat /etc/hostname)"; then
    echo "Workstations does not contain your current hostname ($(cat /etc/hostname))."
    exit 1
  fi

  if ! sudo test -f /etc/ssh/ssh_host_ed25519_key; then
    echo "No host key available."
    exit 1
  fi

  ${perl}/bin/perl -pi -e 's/\Qworkstations = [\E/workstations = [ '"$TARGET_HOSTNAME"'/' public-keys.nix

  readarray -t workstation_secrets < <(grep '++ workstation' secrets.nix | grep -Po '"[^"]+"' | grep -Po '[^"]+')
  for secret_file in "''${workstation_secrets[@]}" ; do
    echo "Renecrypting $secret_file"
    sudo EDITOR=: agenix -i /etc/ssh/ssh_host_ed25519_key -e "$secret_file"
  done

''
