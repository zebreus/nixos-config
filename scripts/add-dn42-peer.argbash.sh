#!/usr/bin/env bash
#
# This is a rather minimal example Argbash potential
# Example taken from http://argbash.readthedocs.io/en/stable/example.html
#
# ARG_POSITIONAL_SINGLE([peering-name], [name of the new peering])
# ARG_HELP([Generates config for a new host that can be deployed with nixos-anywhere])
# ARG_VERSION([echo "1.0.0"])
# ARGBASH_GO

# [ <-- needed because of Argbash

PUBLIC_KEY=""
set -x

function generateKeys {
    PREVIOUS_DIR=$(pwd)
    if [ -z "$PEERING_NAME" ]; then
        echo "Usage: gen-dn42-peering-key <peering_name>"
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

    if grep -F "$PEERING_NAME"_dn42 secrets.nix >/dev/null; then
        echo "Your secrets.nix already contains ''${PEERING_NAME}_dn42. Maybe remove that or just dont run this command."
        exit 1
    fi

    PRIVATE_KEY=$(wg genkey)
    PUBLIC_KEY=$(echo $PRIVATE_KEY | wg pubkey)

    perl -pi -e '$_ = q(  '$PEERING_NAME'_dn42 = "'"$PUBLIC_KEY"'";) . qq(\n) . $_ if /MARKER_WIREGUARD_DN42_PUBLIC_KEYS/' public-keys.nix
    perl -pi -e '$_ = q(  "'$PEERING_NAME'_dn42.age".publicKeys = [ recovery kashenblade blanderdash sempriaq ];) . qq(\n) . $_ if /MARKER_WIREGUARD_DN42_KEYS/' secrets.nix

    echo $PRIVATE_KEY | agenix -e "${PEERING_NAME}_dn42.age"

    echo "Public key: $PUBLIC_KEY"
    echo "Successfully generated wireguard keys for ${PEERING_NAME}"
    cd $PREVIOUS_DIR
}

function generateConfig {
    sed -i 's/dn42Peerings = \[/dn42Peerings = \[ "'"$PEERING_NAME"'"/' machines.nix # ]] <-- needed because of Argbash

    VPN_CONFIG=$(
        cat <<END_HEREDOC
      ${PEERING_NAME} = {
        peerLinkLocal = "fe80::cafe";
        ownLinkLocal = "fe80::beef";
        asNumber = "4242420611";
        publicWireguardEndpoint = "pioneer.sebastians.dev:51822";
        publicWireguardKey = "saICY1kV8JbuPOQNQLtm9TnVP2CuxC0qFSkd69pEKQQ=";
        publicWireguardPort = "2";
        # My public key: ${PUBLIC_KEY}
      };
END_HEREDOC
    )

    perl -pi -e '$_ = qq('"$VPN_CONFIG"'\n) . $_ if /MARKER_PEERING_CONFIGURATIONS/' modules/dn42/peerings.nix
    nix fmt modules/dn42/peerings.nix machines.nix
}

set -e

PEERING_NAME=$_arg_peering_name
SSH_TARGET=$_arg_target

if [ -z "$PEERING_NAME" ]; then
    echo "Usage: $0 PEERING_NAME"
    exit 1
fi

if [ ! -f flake.nix ]; then
    echo "You need to run this script in the root of the nixos config repo"
    exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
    echo "You need to run this script in a clean git repo"
    exit 1
fi

generateKeys

generateConfig

echo "Finished generating config for $PEERING_NAME"

# ] <-- needed because of Argbash
