with import ./public-keys.nix;
{
  # SSH host keys
  # The ed25519 keys are also used for agenix
  # 
  # Can be decrypted by recovery key and self
  # Storing the public keys in here is redundant, but it makes it easier to deploy them
  #
  # Generated with `nix run .#gen-host-keys`
  "erms_ed25519.age".publicKeys = [ recovery erms ];
  "erms_ed25519_pub.age".publicKeys = [ recovery erms ];
  "erms_rsa.age".publicKeys = [ recovery erms ];
  "erms_rsa_pub.age".publicKeys = [ recovery erms ];
  "kashenblade_ed25519.age".publicKeys = [ recovery kashenblade ];
  "kashenblade_ed25519_pub.age".publicKeys = [ recovery kashenblade ];
  "kashenblade_rsa.age".publicKeys = [ recovery kashenblade ];
  "kashenblade_rsa_pub.age".publicKeys = [ recovery kashenblade ];
  "kappril_ed25519.age".publicKeys = [ recovery kappril ];
  "kappril_ed25519_pub.age".publicKeys = [ recovery kappril ];
  "kappril_rsa.age".publicKeys = [ recovery kappril ];
  "kappril_rsa_pub.age".publicKeys = [ recovery kappril ];
  "sempriaq_ed25519.age".publicKeys = [ recovery sempriaq ];
  "sempriaq_ed25519_pub.age".publicKeys = [ recovery sempriaq ];
  "sempriaq_rsa.age".publicKeys = [ recovery sempriaq ];
  "sempriaq_rsa_pub.age".publicKeys = [ recovery sempriaq ];
  "blanderdash_ed25519.age".publicKeys = [ recovery blanderdash ];
  "blanderdash_ed25519_pub.age".publicKeys = [ recovery blanderdash ];
  "blanderdash_rsa.age".publicKeys = [ recovery blanderdash ];
  "blanderdash_rsa_pub.age".publicKeys = [ recovery blanderdash ];
  "prandtl_ed25519.age".publicKeys = [ recovery prandtl ];
  "prandtl_ed25519_pub.age".publicKeys = [ recovery prandtl ];
  "prandtl_rsa.age".publicKeys = [ recovery prandtl ];
  "prandtl_rsa_pub.age".publicKeys = [ recovery prandtl ];
  # MARKER_HOST_KEYS

  # Private user keys
  # Can be decrypted by recovery key, hosts where the user is required, and self
  # These keys should be password protected
  "lennart_ed25519.age".publicKeys = [ recovery lennart ] ++ workstations;
  "lennart_ed25519_pub.age".publicKeys = [ recovery lennart ] ++ workstations;

  # User login passwords
  "lennart_login_passwordhash.age".publicKeys = [ recovery ] ++ workstations;

  # Wireguard keys
  # Can be decrypted by recovery key or the respective machine key
  # Generated with `nix run .#gen-wireguard-keys`
  "erms_wireguard.age".publicKeys = [ recovery erms ];
  "erms_wireguard_pub.age".publicKeys = [ recovery erms ];
  "kashenblade_wireguard.age".publicKeys = [ recovery kashenblade ];
  "kashenblade_wireguard_pub.age".publicKeys = [ recovery kashenblade ];
  "kappril_wireguard.age".publicKeys = [ recovery kappril ];
  "kappril_wireguard_pub.age".publicKeys = [ recovery kappril ];
  "sempriaq_wireguard.age".publicKeys = [ recovery sempriaq ];
  "sempriaq_wireguard_pub.age".publicKeys = [ recovery sempriaq ];
  "blanderdash_wireguard.age".publicKeys = [ recovery blanderdash ];
  "blanderdash_wireguard_pub.age".publicKeys = [ recovery blanderdash ];
  "prandtl_wireguard.age".publicKeys = [ recovery prandtl ];
  "prandtl_wireguard_pub.age".publicKeys = [ recovery prandtl ];
  # MARKER_WIREGUARD_KEYS

  "shared_wireguard_psk.age".publicKeys = [ recovery ] ++ allMachines;

  # Backup secrets
  # For now this is keyed to the machine where the backup is initiated from, but it would make more sense to key it to lennart
  # Generated with `tr -dc A-Za-z0-9 </dev/urandom | head -c 64; echo`
  "lennart_erms_backup_passphrase.age".publicKeys = [ recovery erms lennart ];
  "matrix_backup_passphrase.age".publicKeys = [ recovery kashenblade lennart ];
  "mail_backup_passphrase.age".publicKeys = [ recovery sempriaq lennart ];
  "lennart_prandtl_backup_passphrase.age".publicKeys = [ recovery prandtl lennart ];
  # MARKER_BORG_PASSPHRASES

  # Backup keys
  # These keys are used to connect to borg instances
  # The append_only keys dont have a passphrase, but can only access the backup repository in append-only mode
  # The trusted keys also dont have a passphrase and can access the backup repository in read-write mode. However they can only be decrypted by a password protected user key
  "lennart_erms_backup_append_only_ed25519.age".publicKeys = [ recovery erms lennart ];
  "lennart_erms_backup_append_only_ed25519_pub.age".publicKeys = [ recovery erms lennart ];
  "lennart_erms_backup_trusted_ed25519.age".publicKeys = [ recovery lennart ];
  "lennart_erms_backup_trusted_ed25519_pub.age".publicKeys = [ recovery lennart ];
  "matrix_backup_append_only_ed25519.age".publicKeys = [ recovery kashenblade lennart ];
  "matrix_backup_append_only_ed25519_pub.age".publicKeys = [ recovery kashenblade lennart ];
  "matrix_backup_trusted_ed25519.age".publicKeys = [ recovery lennart ];
  "matrix_backup_trusted_ed25519_pub.age".publicKeys = [ recovery lennart ];
  "mail_backup_append_only_ed25519.age".publicKeys = [ recovery sempriaq lennart ];
  "mail_backup_append_only_ed25519_pub.age".publicKeys = [ recovery sempriaq lennart ];
  "mail_backup_trusted_ed25519.age".publicKeys = [ recovery lennart ];
  "mail_backup_trusted_ed25519_pub.age".publicKeys = [ recovery lennart ];
  "lennart_prandtl_backup_append_only_ed25519.age".publicKeys = [ recovery prandtl lennart ];
  "lennart_prandtl_backup_append_only_ed25519_pub.age".publicKeys = [ recovery prandtl lennart ];
  "lennart_prandtl_backup_trusted_ed25519.age".publicKeys = [ recovery lennart ];
  "lennart_prandtl_backup_trusted_ed25519_pub.age".publicKeys = [ recovery lennart ];
  # MARKER_BORG_BACKUP_KEYS

  # This is secret because it contains information about the infrastructure of other people
  "extra_config.age".publicKeys = [ recovery ] ++ workstations;

  # Shared secret for coturn.
  # Matrix does not support a file option, but can load extra config files, so we use a config file that only sets the secret
  "coturn_static_auth_secret.age".publicKeys = [ recovery kashenblade ];
  "coturn_static_auth_secret_matrix_config.age".publicKeys = [ recovery kashenblade ];

  # Mail server password hashes
  # Generate one with `nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'`
  "lennart_mail_passwordhash.age".publicKeys = [ recovery sempriaq ];
  "lennart_mail_password.age".publicKeys = [ recovery ] ++ workstations;
  "gmail_password.age".publicKeys = [ recovery ] ++ workstations;
  "gmail_oauth2_token.age".publicKeys = [ recovery ] ++ workstations;
  "hda_mail_password.age".publicKeys = [ recovery ] ++ workstations;

  # VPN mail secrets
  # Secrets for the mail accounts inside the antibuilding
  # The secrets include the login to the mail server and the DKIM key for hostname.antibuild.ing
  #
  # Passwords are generated with `tr -dc A-Za-z0-9 </dev/urandom | head -c 64; echo`
  # Password hashes are generated by piping the password into `mkpasswd -sm sha-512 -`
  "erms_dkim_rsa.age".publicKeys = [ recovery sempriaq ];
  "erms_dkim_rsa_pub.age".publicKeys = [ recovery sempriaq ];
  "erms_mail_password.age".publicKeys = [ recovery erms ];
  "erms_mail_passwordhash.age".publicKeys = [ recovery erms sempriaq ];
  "kashenblade_dkim_rsa.age".publicKeys = [ recovery sempriaq ];
  "kashenblade_dkim_rsa_pub.age".publicKeys = [ recovery sempriaq ];
  "kashenblade_mail_password.age".publicKeys = [ recovery kashenblade ];
  "kashenblade_mail_passwordhash.age".publicKeys = [ recovery kashenblade sempriaq ];
  "kappril_dkim_rsa.age".publicKeys = [ recovery sempriaq ];
  "kappril_dkim_rsa_pub.age".publicKeys = [ recovery sempriaq ];
  "kappril_mail_password.age".publicKeys = [ recovery kappril ];
  "kappril_mail_passwordhash.age".publicKeys = [ recovery kappril sempriaq ];
  "sempriaq_dkim_rsa.age".publicKeys = [ recovery sempriaq ];
  "sempriaq_dkim_rsa_pub.age".publicKeys = [ recovery sempriaq ];
  "sempriaq_mail_password.age".publicKeys = [ recovery sempriaq ];
  "sempriaq_mail_passwordhash.age".publicKeys = [ recovery sempriaq ];
  "zebre_us_dkim_rsa.age".publicKeys = [ recovery sempriaq ];
  "zebre_us_dkim_rsa_pub.age".publicKeys = [ recovery sempriaq ];
  "madmanfred_com_dkim_rsa.age".publicKeys = [ recovery sempriaq ];
  "madmanfred_com_dkim_rsa_pub.age".publicKeys = [ recovery sempriaq ];
  "blanderdash_dkim_rsa.age".publicKeys = [ recovery sempriaq ];
  "blanderdash_dkim_rsa_pub.age".publicKeys = [ recovery sempriaq ];
  "blanderdash_mail_password.age".publicKeys = [ recovery blanderdash ];
  "blanderdash_mail_passwordhash.age".publicKeys = [ recovery blanderdash sempriaq ];
  "prandtl_dkim_rsa.age".publicKeys = [ recovery sempriaq ];
  "prandtl_dkim_rsa_pub.age".publicKeys = [ recovery sempriaq ];
  "prandtl_mail_password.age".publicKeys = [ recovery prandtl ];
  "prandtl_mail_passwordhash.age".publicKeys = [ recovery prandtl sempriaq ];
  # MARKER_VPN_MAIL_SECRETS

  # Authoritative DNS server transport key
  # Used for transfering the changed signature records form the primary to the secondary DNS servers
  "knot_transport_key.age".publicKeys = [ recovery ] ++ dnsServers;
}
