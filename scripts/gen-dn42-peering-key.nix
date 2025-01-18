{ pkgs }:
with pkgs; writeScriptBin "gen-dn42-peering-key" ''
  #!${bash}/bin/bash
  PEERING_NAME=$1
  if [ -z "$PEERING_NAME" ]; then
    echo "Usage: gen-dn42-peering-key <peering_name>"
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

  if grep -F "$PEERING_NAME"_dn42 secrets.nix >/dev/null; then
    echo "Your secrets.nix already contains ''${PEERING_NAME}_dn42. Maybe remove that or just dont run this command."
    exit 1
  fi

  PRIVATE_KEY=$(${wireguard-tools}/bin/wg genkey)
  PUBLIC_KEY=$(echo $PRIVATE_KEY | ${wireguard-tools}/bin/wg pubkey)

  ${perl}/bin/perl -pi -e '$_ = q(  '$PEERING_NAME'_dn42 = "'"$PUBLIC_KEY"'";) . qq(\n) . $_ if /MARKER_WIREGUARD_DN42_PUBLIC_KEYS/' public-keys.nix
  ${perl}/bin/perl -pi -e '$_ = q(  "'$PEERING_NAME'_dn42.age".publicKeys = [ recovery kashenblade blanderdash sempriaq ];) . qq(\n) . $_ if /MARKER_WIREGUARD_DN42_KEYS/' secrets.nix

  echo $PRIVATE_KEY | ${pkgs.agenix}/bin/agenix -e "''${PEERING_NAME}_dn42.age"

  echo "Public key: $PUBLIC_KEY"
  echo "Successfully generated wireguard keys for ''${PEERING_NAME}"
''

