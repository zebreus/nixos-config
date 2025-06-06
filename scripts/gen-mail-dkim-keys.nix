{ pkgs }:
with pkgs; writeScriptBin "gen-mail-dkim-keys" ''
  #!${bash}/bin/bash
  DOMAIN_NAME=$1

  if [[ -z "$DOMAIN_NAME" ]]; then
    echo "Usage: gen-mail-dkim-keys <DOMAIN_NAME>"
    echo "DOMAIN_NAME name of the domain you want to generate DKIM keys for."
    echo "Example: gen-mail-dkim-keys zebre_us"
    exit 1
  fi
  set -x
  set -e

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

  if grep -F "$DOMAIN_NAME"_dkim_rsa secrets.nix >/dev/null; then
    echo "Your secrets.nix already mentions ''${DOMAIN_NAME}_dkim_rsa. Are you sure you want to do this?"
    exit 1
  fi

  function add_dkim_key {
    VPN_MAIL_SECRETS_MARKER="MARKER_VPN_MAIL_SECRETS"
    VPN_MAIL_PUBLIC_KEYS_MARKER="MARKER_VPN_MAIL_DKIM_PUBLIC_KEYS"

    PUBLIC_KEY_NAME=''${DOMAIN_NAME}_dkim
    PRIVATE_KEY_SECRETS_NAME="$PUBLIC_KEY_NAME"_rsa.age
    PUBLIC_KEY_SECRETS_NAME="$PUBLIC_KEY_NAME"_rsa_pub.age

    PRIVATE_KEY=$(${lib.getExe pkgs.openssl} genrsa 4096)
    PUBLIC_KEY=$(echo "$PRIVATE_KEY" | ${lib.getExe pkgs.openssl} rsa -pubout -outform der | ${lib.getExe pkgs.openssl} base64 -A)


    ${perl}/bin/perl -pi -e '$_ = q(  '$PUBLIC_KEY_NAME' = "'"$PUBLIC_KEY"'";) . qq(\n) . $_ if /'"$VPN_MAIL_PUBLIC_KEYS_MARKER"'/' public-keys.nix
    ${perl}/bin/perl -pi -e '$_ = q(  "'$PRIVATE_KEY_SECRETS_NAME'".publicKeys = [ recovery ] ++ mailServers ;) . qq(\n) . $_ if /'"$VPN_MAIL_SECRETS_MARKER"'/' secrets.nix
    ${perl}/bin/perl -pi -e '$_ = q(  "'$PUBLIC_KEY_SECRETS_NAME'".publicKeys = [ recovery ] ++ mailServers ;) . qq(\n) . $_ if /'"$VPN_MAIL_SECRETS_MARKER"'/' secrets.nix

    echo "$PRIVATE_KEY" | ${pkgs.agenix}/bin/agenix -e "$PRIVATE_KEY_SECRETS_NAME"
    echo "$PUBLIC_KEY" | ${pkgs.agenix}/bin/agenix -e "$PUBLIC_KEY_SECRETS_NAME"
  }

  add_dkim_key

  echo "Successfully added a dkim key for ''${DOMAIN_NAME}"

  echo "The DKIM private key was written to secrets.nix"
  echo "The DKIM public key was written to secrets.nix and public-keys.nix"
''
