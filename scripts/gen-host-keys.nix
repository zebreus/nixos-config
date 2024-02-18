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
      echo "You need to run this script in the directory with the agenix secrets.nix"
      exit 1
    fi

    cd secrets

    if [ ! -f secrets.nix ]; then
      echo "You need to run this script in the directory with the agenix secrets.nix2"
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
  ${perl}/bin/perl -pi -e '$_ = q(  "'$TARGET_HOSTNAME'_ed25519.age".publicKeys = [ recovery '$TARGET_HOSTNAME' ];) . qq(\n) . $_ if /MARKER_HOST_KEYS/' secrets.nix
  ${perl}/bin/perl -pi -e '$_ = q(  "'$TARGET_HOSTNAME'_ed25519_pub.age".publicKeys = [ recovery '$TARGET_HOSTNAME' ];) . qq(\n) . $_ if /MARKER_HOST_KEYS/' secrets.nix
  ${perl}/bin/perl -pi -e '$_ = q(  "'$TARGET_HOSTNAME'_rsa.age".publicKeys = [ recovery '$TARGET_HOSTNAME' ];) . qq(\n) . $_ if /MARKER_HOST_KEYS/' secrets.nix
  ${perl}/bin/perl -pi -e '$_ = q(  "'$TARGET_HOSTNAME'_rsa_pub.age".publicKeys = [ recovery '$TARGET_HOSTNAME' ];) . qq(\n) . $_ if /MARKER_HOST_KEYS/' secrets.nix
  ${perl}/bin/perl -pi -e 's/\QallMachines = [\E/allMachines = [ '"$TARGET_HOSTNAME"'/' public-keys.nix 
        
  cat $KEYDIR/''${TARGET_HOSTNAME}_ed25519 | ${pkgs.agenix}/bin/agenix -e "''${TARGET_HOSTNAME}_ed25519.age"
  cat $KEYDIR/''${TARGET_HOSTNAME}_ed25519.pub | ${pkgs.agenix}/bin/agenix -e "''${TARGET_HOSTNAME}_ed25519_pub.age"
  cat $KEYDIR/''${TARGET_HOSTNAME}_rsa | ${pkgs.agenix}/bin/agenix -e "''${TARGET_HOSTNAME}_rsa.age"
  cat $KEYDIR/''${TARGET_HOSTNAME}_rsa.pub | ${pkgs.agenix}/bin/agenix -e "''${TARGET_HOSTNAME}_rsa_pub.age"

  echo "Successfully generated keys for ''${TARGET_HOSTNAME}"
  echo "The public ed25519 was written to secrets.nix and all other keys were added to agenix"
  echo "The unencrypted private key is at $KEYDIR/''${TARGET_HOSTNAME}_ed25519"
''
