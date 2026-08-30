{ pkgs }:
with pkgs; writeScriptBin "gen-wireguard-keys" ''
  #!${bash}/bin/bash
  TARGET_HOSTNAME=$1
  if [ -z "$TARGET_HOSTNAME" ]; then
    echo "Usage: gen-wireguard-keys <target_hostname>"
    exit 1
  fi

  KEYDIR=$HOME/.ssh

  if [ ! -f secrets.nix ]; then
    if [ ! -d secrets ]; then
      echo "You need to run this script in the directory with the geheimnix secrets.nix"
      exit 1
    fi

    cd secrets

    if [ ! -f secrets.nix ]; then
      echo "You need to run this script in the directory with the geheimnix secrets.nix2"
      exit 1
    fi
  fi

  # if ! grep -F "$TARGET_HOSTNAME"_ed25519 secrets.nix >/dev/null; then
  #   echo "Your secrets.nix does not mention ''${TARGET_HOSTNAME}_ed25519 . Run gen-host-keys first."
  #   exit 1
  # fi

  if grep -F "$TARGET_HOSTNAME"_wireguard secrets.nix >/dev/null; then
    echo "Your secrets.nix already contains ''${TARGET_HOSTNAME}_wireguard. Maybe remove that or just dont run this command."
    exit 1
  fi

  PRIVATE_KEY=$(${wireguard-tools}/bin/wg genkey)
  PUBLIC_KEY=$(echo $PRIVATE_KEY | ${wireguard-tools}/bin/wg pubkey)
  PRESHARED_KEY=$(${wireguard-tools}/bin/wg genpsk)

  ${perl}/bin/perl -pi -e '$_ = q(  '$TARGET_HOSTNAME'_wireguard = "'"$PUBLIC_KEY"'";) . qq(\n) . $_ if /MARKER_WIREGUARD_PUBLIC_KEYS/' public-keys.nix
  ${perl}/bin/perl -pi -e '$_ = q(  "'$TARGET_HOSTNAME'_wireguard".publicKeys = [ recovery '$TARGET_HOSTNAME' ];) . qq(\n) . $_ if /MARKER_WIREGUARD_KEYS/' secrets.nix
  ${perl}/bin/perl -pi -e '$_ = q(  "'$TARGET_HOSTNAME'_wireguard_pub".publicKeys = [ recovery '$TARGET_HOSTNAME' ];) . qq(\n) . $_ if /MARKER_WIREGUARD_KEYS/' secrets.nix
        
  echo $PRIVATE_KEY | ${pkgs.geheimnix}/bin/geheimnix encrypt --force "''${TARGET_HOSTNAME}_wireguard"
  echo $PUBLIC_KEY | ${pkgs.geheimnix}/bin/geheimnix encrypt --force "''${TARGET_HOSTNAME}_wireguard_pub"

  echo "Successfully generated wireguard keys for ''${TARGET_HOSTNAME}"
''
