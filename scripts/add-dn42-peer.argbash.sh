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

    THEIR_WIREGUARD_ENDPOINT_LINE=""
    if [ -n "$THEIR_WIREGUARD_ENDPOINT" ]; then
        THEIR_WIREGUARD_ENDPOINT_LINE="publicWireguardEndpoint = "'"'"${THEIR_WIREGUARD_ENDPOINT}"'"'";"
    fi

    VPN_CONFIG=$(
        cat <<END_HEREDOC
      ${PEERING_NAME} = {
        peerLinkLocal = "${MY_LINK_LOCAL}";
        ownLinkLocal = "${THEIR_LINK_LOCAL}";
        asNumber = "${THEIR_AS}";
        ${THEIR_WIREGUARD_ENDPOINT_LINE}
        publicWireguardKey = "${THEIR_WIREGUARD_PUBLIC_KEY}";
        publicWireguardPort = "${MY_WIREGUARD_PORT}";
        # My public key: ${PUBLIC_KEY}
        # My endpoint: ${MY_WIREGUARD_HOST}:${MY_WIREGUARD_PORT}
        # My link local: ${MY_LINK_LOCAL}
        # My AS: ${MY_AS}
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

MY_WIREGUARD_PORT="$(shuf -i 1-30000 -n 1)"
MY_WIREGUARD_HOST="${PEERING_NAME}.dn42.antibuild.ing"
MY_LINK_LOCAL="fe80::1234:9320"
MY_AS="4242421403"

echo "What is their wireguard host:port? (Leave empty if they dont have a static address)"
read THEIR_WIREGUARD_ENDPOINT
if [ -z "$THEIR_WIREGUARD_ENDPOINT" ]; then
    echo "No wireguard endpoint given. Assuming they dont have a static address."
fi

echo "What is their wireguard public key? (Leave empty if you dont know yet)"
read THEIR_WIREGUARD_PUBLIC_KEY
if [ -z "$THEIR_WIREGUARD_PUBLIC_KEY" ]; then
    THEIR_WIREGUARD_PUBLIC_KEY="TODO"
fi

echo "What is their link local address in the tunnel? (Leave empty if you dont know yet)"
read THEIR_LINK_LOCAL
if [ -z "$THEIR_LINK_LOCAL" ]; then
    THEIR_LINK_LOCAL="fe80::8943:2034:2342"
fi

echo "What is their AS? (Leave empty if you dont know yet)"
read THEIR_AS
if [ -z "$THEIR_AS" ]; then
    THEIR_AS="12345"
fi

generateKeys
generateConfig

echo "Finished generating config for $PEERING_NAME"
echo "You can give them the following message:"
echo ""
echo "Hey there :) Here are the details for our new dn42 peering:"
echo "My wireguard peer is reachable at \`${MY_WIREGUARD_HOST}:${MY_WIREGUARD_PORT}\`"
echo "It uses the public key \`${PUBLIC_KEY}\`"
if [ "$THEIR_WIREGUARD_PUBLIC_KEY" == "TODO" ]; then
    echo "!! Please provide me with your wireguard public key !!"
else
    echo "Your public key is: \`${THEIR_WIREGUARD_PUBLIC_KEY}\`"
fi
if [ "$THEIR_WIREGUARD_ENDPOINT" != "" ]; then
    echo "You have provided me with the endpoint \`${THEIR_WIREGUARD_ENDPOINT}\`"
fi
echo "Inside the tunnel, my link local address is \`${MY_LINK_LOCAL}\`\n"
echo "Your link-local in the tunnel is \`${THEIR_LINK_LOCAL}\`\n"
if [ "$THEIR_LINK_LOCAL" = "fe80::8943:2034:2342" ]; then
    echo "!! If you want to use a different link-local address, please let me know !!"
fi
echo "My AS is \`${MY_AS}\`"
if [ "$THEIR_AS" = "12345" ]; then
    echo "!! I still need to know your AS number !!"
else
    echo "Your AS is \`${THEIR_AS}\`"
fi

echo "My public key"

# ] <-- needed because of Argbash
