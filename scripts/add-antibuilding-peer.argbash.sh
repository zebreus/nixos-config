#!/usr/bin/env bash
#
# ARG_POSITIONAL_SINGLE([hostname], [hostname of the new machine])
# ARG_POSITIONAL_SINGLE([wireguard-public-key], [the wireguard public key of your machine])
# ARG_OPTIONAL_SINGLE([public-ipv4], [], [public ipv4 address of the machine. Leave empty if the machine has none])
# ARG_OPTIONAL_SINGLE([public-ipv6], [], [public ipv6 address of the machine. Leave empty if the machine has none])
# ARG_HELP([Generates a commit in this repository, that configures the wireguard VPN with a new host])
# ARG_VERSION([echo "1.0.0"])
# ARGBASH_GO

# [ <-- needed because of Argbash

function generatePeerConfig {
    local highest_id="$(grep "address" machines.nix | grep -Po "[0-9]+" | sort -nr | head -n1)"
    local new_id=$((highest_id+1))

    echo Generating host entries in flake.nix
    FLAKE_MACHINE_CONFIGURATION=$(
        cat <<END_HEREDOC
${PEER_HOSTNAME} = {
  name = "${PEER_HOSTNAME}";
  address = ${new_id};
  wireguardPublicKey = publicKeys.${PEER_HOSTNAME}_wireguard;
};
END_HEREDOC
    )

    perl -pi -e '$_ = q(  '$PEER_HOSTNAME'_wireguard = "'"$WIREGUARD_PUBLIC_KEY"'";) . qq(\n) . $_ if /MARKER_WIREGUARD_PUBLIC_KEYS/' secrets/public-keys.nix
    perl -pi -e '$_ = qq('"$FLAKE_MACHINE_CONFIGURATION"'\n) . $_ if /MARKER_MACHINE_CONFIGURATIONS/' machines.nix

    nix fmt machines.nix secrets/public-keys.nix
    git add machines.nix secrets/public-keys.nix
    git commit -m "Add antibuilding peer ${PEER_HOSTNAME}"
}

set -e

PEER_HOSTNAME=$_arg_hostname
WIREGUARD_PUBLIC_KEY=$_arg_wireguard_public_key

if [ -z "$WIREGUARD_PUBLIC_KEY" ] || [ -z "$PEER_HOSTNAME" ]; then
    echo "Usage: $0 YOUR_HOST_NAME WIREGUARD_PUBLIC_KEY"
    exit 1
fi

if [ ! -f flake.nix ]; then
    echo "You need to run this script in the root of the nixos config repo"
    exit 1
fi

if grep -q "$PEER_HOSTNAME" flake.nix; then
    echo "$PEER_HOSTNAME is already mentioned in flake.nix"
    exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
    echo "You need to run this script in a clean git repo"
    exit 1
fi

generatePeerConfig

echo "Added configuration for $PEER_HOSTNAME to the repo."
echo "Please commit your changes and open a PR. After the PR is merged"
echo "it can take up to one hour until all machines know about your"
echo "machine. The Readme describes the setup that you need to do on"
echo "your machine."
# Use sbctl create-keys --database-path /tmp/secret/etc/secureboot --export /tmp/secret/etc/secureboot/keys to create secure boot keys

# ] <-- needed because of Argbash
