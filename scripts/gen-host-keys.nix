{ pkgs }:
with pkgs; writeScriptBin "gen-host-keys" ''
  #!${bash}/bin/bash
  TARGET_HOSTNAME=$1
  if [ -z "$TARGET_HOSTNAME" ]; then
    echo "Usage: gen-host-keys <target_hostname>"
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

  if grep -F "$TARGET_HOSTNAME"_ed25519 secrets.nix >/dev/null; then
    echo "Your secrets.nix already mentions ''${TARGET_HOSTNAME}_ed25519. Are you sure you want to do this?"
    exit 1
  fi

  echo "Generating keys for ''${TARGET_HOSTNAME}"

  ${openssh}/bin/ssh-keygen -t ed25519 -N "" -f $KEYDIR/''${TARGET_HOSTNAME}_ed25519 -C root@''${TARGET_HOSTNAME}
  ${openssh}/bin/ssh-keygen -t rsa -b 8192 -N "" -f $KEYDIR/''${TARGET_HOSTNAME}_rsa -C root@''${TARGET_HOSTNAME}

  PUBLIC_KEY=$(cat $KEYDIR/''${TARGET_HOSTNAME}_ed25519.pub)

  ${perl}/bin/perl -pi -e '$_ = q(  '$TARGET_HOSTNAME' = "'"$PUBLIC_KEY"'";) . qq(\n) . $_ if /MARKER_PUBLIC_HOST_KEYS/' public-keys.nix
  ${perl}/bin/perl -pi -e '$_ = q(  "'$TARGET_HOSTNAME'_ed25519".publicKeys = [ recovery '$TARGET_HOSTNAME' ];) . qq(\n) . $_ if /MARKER_HOST_KEYS/' secrets.nix
  ${perl}/bin/perl -pi -e '$_ = q(  "'$TARGET_HOSTNAME'_ed25519_pub".publicKeys = [ recovery '$TARGET_HOSTNAME' ];) . qq(\n) . $_ if /MARKER_HOST_KEYS/' secrets.nix
  ${perl}/bin/perl -pi -e '$_ = q(  "'$TARGET_HOSTNAME'_rsa".publicKeys = [ recovery '$TARGET_HOSTNAME' ];) . qq(\n) . $_ if /MARKER_HOST_KEYS/' secrets.nix
  ${perl}/bin/perl -pi -e '$_ = q(  "'$TARGET_HOSTNAME'_rsa_pub".publicKeys = [ recovery '$TARGET_HOSTNAME' ];) . qq(\n) . $_ if /MARKER_HOST_KEYS/' secrets.nix
  ${perl}/bin/perl -pi -e 's/\QallMachines = [\E/allMachines = [ '"$TARGET_HOSTNAME"'/' public-keys.nix 
        
  cat $KEYDIR/''${TARGET_HOSTNAME}_ed25519 | ${pkgs.geheimnix}/bin/geheimnix encrypt --force "''${TARGET_HOSTNAME}_ed25519"
  cat $KEYDIR/''${TARGET_HOSTNAME}_ed25519.pub | ${pkgs.geheimnix}/bin/geheimnix encrypt --force "''${TARGET_HOSTNAME}_ed25519_pub"
  cat $KEYDIR/''${TARGET_HOSTNAME}_rsa | ${pkgs.geheimnix}/bin/geheimnix encrypt --force "''${TARGET_HOSTNAME}_rsa"
  cat $KEYDIR/''${TARGET_HOSTNAME}_rsa.pub | ${pkgs.geheimnix}/bin/geheimnix encrypt --force "''${TARGET_HOSTNAME}_rsa_pub"

  echo "Successfully generated keys for ''${TARGET_HOSTNAME}"
  echo "The public ed25519 was written to secrets.nix and all other keys were added to geheimnix"
  echo "The unencrypted private key is at $KEYDIR/''${TARGET_HOSTNAME}_ed25519"
''
