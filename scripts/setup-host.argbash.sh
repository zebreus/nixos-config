#!/usr/bin/env bash
#
# This is a rather minimal example Argbash potential
# Example taken from http://argbash.readthedocs.io/en/stable/example.html
#
# ARG_POSITIONAL_SINGLE([hostname], [hostname of the new machine])
# ARG_POSITIONAL_SINGLE([target], [ssh hostname to the target machine. Usually like "root@1.2.3.4"])
# ARG_OPTIONAL_SINGLE([boot], [], [bootloader type. Can be "auto", "efi", or "legacy". Auto will ssh into the target host and autodetect the boot type], [auto])
# ARG_OPTIONAL_BOOLEAN([secrets], , [Generate new secrets.], [on])
# ARG_OPTIONAL_BOOLEAN([machine], , [Insert a template for the new machine into machines and flake.nix.], [on])
# ARG_OPTIONAL_BOOLEAN([workstation], , [Set to true if this machine should be used interactivly.], [off])
# ARG_HELP([Generates config for a new host that can be deployed with nixos-anywhere])
# ARG_VERSION([echo "1.0.0"])
# ARGBASH_GO

# [ <-- needed because of Argbash

function generateSecrets {
    if [ "$_arg_secrets" == "on" ]; then
        cd secrets

        echo Generating secrets
        set -x
        nix run .#gen-host-keys "$TARGET_HOST_NAME"
        nix run .#gen-wireguard-keys "$TARGET_HOST_NAME"
        nix run .#gen-vpn-mail-secrets "$TARGET_HOST_NAME" sempriaq
        git add .
        set +x

        echo Reeencrypting the secrets
        sudo EDITOR=: agenix -e shared_wireguard_psk.age -i /etc/ssh/ssh_host_ed25519_key
        git add .

        if [ "$_arg_workstation" == "on" ]; then
            echo Reencrypting the secrets for the workstation
            nix run .#add-workstation "$TARGET_HOST_NAME"

            echo "Adding backup keys for the workstation"
            nix run .#gen-borg-keys -- lennart_"$TARGET_HOST_NAME"_backup "$TARGET_HOST_NAME" "lennart"
        fi

        cd ..
    fi

    test -f ~/.ssh/"${TARGET_HOST_NAME}_ed25519" || {
        echo You should have a private host key for "$TARGET_HOST_NAME" at ~/.ssh/"${TARGET_HOST_NAME}_ed25519"
        exit 1
    }

    echo Preparing secrets directory for nixos-anywhere
    SECRETS_DIR=$(mktemp -d)
    # Create the directory where sshd expects to find the host keys
    install -d -m755 "$SECRETS_DIR/etc/ssh"
    cp ~/.ssh/"${TARGET_HOST_NAME}_ed25519" "$SECRETS_DIR/etc/ssh/ssh_host_ed25519_key"
    chmod 600 "$SECRETS_DIR/etc/ssh/ssh_host_ed25519_key"
}

function generateMachineConfig {
    if [ "$_arg_machine" == "off" ]; then
        return
    fi
    echo Generating host entries in flake.nix
    FLAKE_MACHINE_CONFIGURATION=$(
        cat <<END_HEREDOC
${TARGET_HOST_NAME} = {
  name = "${TARGET_HOST_NAME}";
  address = 9;
  wireguardPublicKey = publicKeys.${TARGET_HOST_NAME}_wireguard;
  trusted = true;
  sshPublicKey = publicKeys.${TARGET_HOST_NAME};
};
END_HEREDOC
    )

    FLAKE_NIXOS_CONFIGURATION=$(
        cat <<END_HEREDOC
${TARGET_HOST_NAME} = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    agenix.nixosModules.default
    disko.nixosModules.disko
    overlayNixpkgs
    informationAboutOtherMachines
    home-manager.nixosModules.home-manager
    simple-nix-mailserver.nixosModules.default
    gnome-online-accounts-config.nixosModules.default
    ./machines/${TARGET_HOST_NAME}
  ];
};
END_HEREDOC
    )

    perl -pi -e '$_ = qq('"$FLAKE_MACHINE_CONFIGURATION"'\n) . $_ if /MARKER_MACHINE_CONFIGURATIONS/' machines.nix
    perl -pi -e '$_ = qq('"$FLAKE_NIXOS_CONFIGURATION"'\n) . $_ if /MARKER_NIXOS_CONFIGURATIONS/' flake.nix
    nix fmt flake.nix machines.nix

    cp -rT machines/template-host machines/"$TARGET_HOST_NAME"
    find machines/"$TARGET_HOST_NAME" -type f -exec sed -i "s/template-host/$TARGET_HOST_NAME/g" {} \;

    if [ "$BOOT_TYPE" != "efi" ]; then
        perl -pi -e '$_ = $_ . qq(modules.boot.type = "'"$BOOT_TYPE"'";\n) if /networking.hostName/' machines/"$TARGET_HOST_NAME"/default.nix
        nix fmt machines/"$TARGET_HOST_NAME"/default.nix
    fi

    git add flake.nix machines/"$TARGET_HOST_NAME"
}

set -e

TARGET_HOST_NAME=$_arg_hostname
SSH_TARGET=$_arg_target

if [ -z "$SSH_TARGET" ] || [ -z "$TARGET_HOST_NAME" ]; then
    echo "Usage: $0 TARGET_HOST_NAME SSH_TARGET"
    exit 1
fi

if [ ! -f flake.nix ]; then
    echo "You need to run this script in the root of the nixos config repo"
    exit 1
fi

if [ -e machines/"$TARGET_HOST_NAME"/default.nix ]; then
    echo "There already is a directory for $TARGET_HOST_NAME in machines"
    exit 1
fi

if grep -q "$TARGET_HOST_NAME" flake.nix; then
    echo "$TARGET_HOST_NAME is already mentioned in flake.nix"
    exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
    echo "You need to run this script in a clean git repo"
    exit 1
fi

function test-ssh {
    test "$(ssh -o StrictHostKeyChecking=no "$SSH_TARGET" echo working)" == "working"
}

if ! test-ssh; then
    echo "Removing old signature for $SSH_TARGET from known hosts"
    ssh-keygen -R "$(echo "$SSH_TARGET" | cut -d"@" -f2)"
fi

if ! test-ssh; then
    echo "Installing ssh host key to $SSH_TARGET"
    ssh-copy-id -o StrictHostKeyChecking=no -o PreferredAuthentications=password -f -i ~/.ssh/id_ed25519.pub "$SSH_TARGET"
fi

if ! test-ssh; then
    echo "Failed to connect to $SSH_TARGET"
    exit 1
fi

if [ "$_arg_boot" == "auto" ]; then
    echo "Figuring out boot type"
    BOOT_TYPE=$(ssh "$SSH_TARGET" sh -c "dmesg | grep 'EFI v' >/dev/null && echo efi || echo legacy")
    echo "Boot type is $BOOT_TYPE"
    if test -z "$BOOT_TYPE"; then
        echo "Failed to determine boot type"
        exit 1
    fi
else
    BOOT_TYPE=$_arg_boot
fi

if [ "$BOOT_TYPE" != "legacy" ] && [ "$BOOT_TYPE" != "efi" ]; then
    echo "Invalid boot type $BOOT_TYPE"
    exit 1
fi

generateSecrets

generateMachineConfig

echo "Finished preparing secrets for $TARGET_HOST_NAME"
echo "You should now add the new host in machines and flake.nix"
echo "Then run the following command to deploy the host:"
echo "nixos-anywhere --extra-files $SECRETS_DIR --build-on-remote --flake .#$TARGET_HOST_NAME $SSH_TARGET"
# Use sbctl create-keys --database-path /tmp/secret/etc/secureboot --export /tmp/secret/etc/secureboot/keys to create secure boot keys

# ] <-- needed because of Argbash
