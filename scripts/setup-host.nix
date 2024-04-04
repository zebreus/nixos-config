{ pkgs, lib }:
with pkgs; writeScriptBin "setup-host" ''
  #!${lib.getExe bash}

  set -e

  TARGET_HOST_NAME=$1
  SSH_TARGET=$2

  if [ -z "$SSH_TARGET" ] || [ -z "$TARGET_HOST_NAME" ]; then
    echo "Usage: $0 TARGET_HOST_NAME SSH_TARGET"
    exit 1
  fi

  if [ ! -f flake.nix ]; then
    echo "You need to run this script in the root of the nixos config repo"
    exit 1
  fi

  if [ -e machines/"$TARGET_HOST_NAME" ]; then
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
    test "$(ssh -o StrictHostKeyChecking=no $SSH_TARGET echo working)" == "working"
  }

  if ! test-ssh ; then
    echo "Installing ssh host key to $SSH_TARGET"
    ssh-copy-id  -o StrictHostKeyChecking=no -o PreferredAuthentications=password  -f -i ~/.ssh/id_ed25519.pub $SSH_TARGET
  fi

  if ! test-ssh ; then
    echo "Failed to connect to $SSH_TARGET"
    exit 1
  fi

  echo "Figuring out boot type"
  BOOT_TYPE=$(ssh $SSH_TARGET sh -c "dmesg | grep 'EFI v' >/dev/null && echo efi || echo legacy")
  echo "Boot type is $BOOT_TYPE"
  if test -z "$BOOT_TYPE"; then
    echo "Failed to determine boot type"
    exit 1
  fi

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
  
  cd ..

  echo Preparing secrets directory for nixos-anywhere
  SECRETS_DIR=$(mktemp -d)
  # Create the directory where sshd expects to find the host keys
  install -d -m755 "$SECRETS_DIR/etc/ssh"
  cp ~/.ssh/"''${TARGET_HOST_NAME}_ed25519" "$SECRETS_DIR/etc/ssh/ssh_host_ed25519_key"
  chmod 600 "$SECRETS_DIR/etc/ssh/ssh_host_ed25519_key"

  SCRATCH_DIR=$(mktemp -d)
  echo Generating host entries in flake.nix
  FLAKE_MACHINE_CONFIGURATION=$(
  cat <<END_HEREDOC
  ''${TARGET_HOST_NAME} = {
    name = "''${TARGET_HOST_NAME}";
    address = 9;
    wireguardPublicKey = publicKeys.''${TARGET_HOST_NAME}_wireguard;
    trusted = true;
    sshPublicKey = publicKeys.''${TARGET_HOST_NAME};
  };
  END_HEREDOC
  )

  FLAKE_NIXOS_CONFIGURATION=$(
  cat <<END_HEREDOC
  ''${TARGET_HOST_NAME} = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = attrs;
    modules = [
      agenix.nixosModules.default
      disko.nixosModules.disko
      overlayNixpkgs
      informationAboutOtherMachines
      home-manager.nixosModules.home-manager
      simple-nix-mailserver.nixosModules.default
      gnome-online-accounts-config.nixosModules.default
      ./machines/''${TARGET_HOST_NAME}
    ];
  };
  END_HEREDOC
  )

  perl -pi -e '$_ = qq('"$FLAKE_MACHINE_CONFIGURATION"'\n) . $_ if /MARKER_MACHINE_CONFIGURATIONS/' flake.nix
  perl -pi -e '$_ = qq('"$FLAKE_NIXOS_CONFIGURATION"'\n) . $_ if /MARKER_NIXOS_CONFIGURATIONS/' flake.nix
  nix fmt flake.nix

  cp -r machines/template-host machines/"$TARGET_HOST_NAME"
  find machines/"$TARGET_HOST_NAME" -type f -exec sed -i "s/template-host/$TARGET_HOST_NAME/g" {} \;

  if [ "$BOOT_TYPE" != "efi" ]; then
    perl -pi -e '$_ = $_ . qq(modules.boot.type = "'"$BOOT_TYPE"'";\n) if /networking.hostName/' machines/$TARGET_HOST_NAME/default.nix
    nix fmt machines/$TARGET_HOST_NAME/default.nix
  fi

  git add flake.nix machines/"$TARGET_HOST_NAME"

  echo "Finished preparing secrets for $TARGET_HOST_NAME"
  echo "You should now add the new host in machines and flake.nix"
  echo "Then run the following command to deploy the host:"
  echo "nixos-anywhere --extra-files "$SECRETS_DIR" --build-on-remote --flake .#$TARGET_HOST_NAME $SSH_TARGET"
''
