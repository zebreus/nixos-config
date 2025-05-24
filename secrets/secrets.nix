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
  "glouble_ed25519.age".publicKeys = [ recovery glouble ];
  "glouble_ed25519_pub.age".publicKeys = [ recovery glouble ];
  "glouble_rsa.age".publicKeys = [ recovery glouble ];
  "glouble_rsa_pub.age".publicKeys = [ recovery glouble ];
  # MARKER_HOST_KEYS

  # Private user keys
  # Can be decrypted by recovery key, hosts where the user is required, and self
  # These keys should be password protected
  "lennart_ed25519.age".publicKeys = [ recovery lennart ] ++ workstations;
  "lennart_ed25519_pub.age".publicKeys = [ recovery lennart ] ++ workstations;

  # Extra SSH keys
  "w17_door_ed25519.age".publicKeys = [ recovery ] ++ workstations;
  "w17_door_ed25519_pub.age".publicKeys = [ recovery ] ++ workstations;

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
  "glouble_wireguard.age".publicKeys = [ recovery glouble ];
  "glouble_wireguard_pub.age".publicKeys = [ recovery glouble ];
  # MARKER_WIREGUARD_KEYS

  "shared_wireguard_psk.age".publicKeys = [ recovery ] ++ allMachines;

  # Backup secrets
  # For now this is keyed to the machine where the backup is initiated from, but it would make more sense to key it to lennart
  # Generated with `tr -dc A-Za-z0-9 </dev/urandom | head -c 64; echo`
  "lennart_erms_backup_passphrase.age".publicKeys = [ recovery erms lennart ];
  "matrix_backup_passphrase.age".publicKeys = [ recovery kashenblade lennart ];
  "mail_backup_passphrase.age".publicKeys = [ recovery lennart ] ++ mailServers;
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
  "mail_backup_append_only_ed25519.age".publicKeys = [ recovery lennart ] ++ mailServers;
  "mail_backup_append_only_ed25519_pub.age".publicKeys = [ recovery lennart ] ++ mailServers;
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
  "lennart_mail_passwordhash.age".publicKeys = [ recovery ] ++ mailServers;
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
  "erms_dkim_rsa.age".publicKeys = [ recovery ] ++ mailServers;
  "erms_dkim_rsa_pub.age".publicKeys = [ recovery ] ++ mailServers;
  "erms_mail_password.age".publicKeys = [ recovery erms ];
  "erms_mail_passwordhash.age".publicKeys = [ recovery erms ] ++ mailServers;
  "kashenblade_dkim_rsa.age".publicKeys = [ recovery ] ++ mailServers;
  "kashenblade_dkim_rsa_pub.age".publicKeys = [ recovery ] ++ mailServers;
  "kashenblade_mail_password.age".publicKeys = [ recovery kashenblade ];
  "kashenblade_mail_passwordhash.age".publicKeys = [ recovery kashenblade ] ++ mailServers;
  "kappril_dkim_rsa.age".publicKeys = [ recovery ] ++ mailServers;
  "kappril_dkim_rsa_pub.age".publicKeys = [ recovery ] ++ mailServers;
  "kappril_mail_password.age".publicKeys = [ recovery kappril ];
  "kappril_mail_passwordhash.age".publicKeys = [ recovery kappril ] ++ mailServers;
  "sempriaq_dkim_rsa.age".publicKeys = [ recovery ] ++ mailServers;
  "sempriaq_dkim_rsa_pub.age".publicKeys = [ recovery ] ++ mailServers;
  "sempriaq_mail_password.age".publicKeys = [ recovery sempriaq ];
  "sempriaq_mail_passwordhash.age".publicKeys = [ recovery sempriaq ] ++ mailServers;
  "zebre_us_dkim_rsa.age".publicKeys = [ recovery ] ++ mailServers;
  "zebre_us_dkim_rsa_pub.age".publicKeys = [ recovery ] ++ mailServers;
  "madmanfred_com_dkim_rsa.age".publicKeys = [ recovery ] ++ mailServers;
  "madmanfred_com_dkim_rsa_pub.age".publicKeys = [ recovery ] ++ mailServers;
  "blanderdash_dkim_rsa.age".publicKeys = [ recovery ] ++ mailServers;
  "blanderdash_dkim_rsa_pub.age".publicKeys = [ recovery ] ++ mailServers;
  "blanderdash_mail_password.age".publicKeys = [ recovery blanderdash ];
  "blanderdash_mail_passwordhash.age".publicKeys = [ recovery blanderdash ] ++ mailServers;
  "prandtl_dkim_rsa.age".publicKeys = [ recovery ] ++ mailServers;
  "prandtl_dkim_rsa_pub.age".publicKeys = [ recovery ] ++ mailServers;
  "prandtl_mail_password.age".publicKeys = [ recovery prandtl ];
  "prandtl_mail_passwordhash.age".publicKeys = [ recovery prandtl ] ++ mailServers;
  "antibuild_ing_dkim_rsa.age".publicKeys = [ recovery ] ++ mailServers;
  "antibuild_ing_dkim_rsa_pub.age".publicKeys = [ recovery ] ++ mailServers;
  "glouble_dkim_rsa.age".publicKeys = [ recovery sempriaq ];
  "glouble_dkim_rsa_pub.age".publicKeys = [ recovery sempriaq ];
  "glouble_mail_password.age".publicKeys = [ recovery glouble ];
  "glouble_mail_passwordhash.age".publicKeys = [ recovery glouble sempriaq ];
  # MARKER_VPN_MAIL_SECRETS

  # Authoritative DNS server transport key
  # Used for transfering the changed signature records form the primary to the secondary DNS servers
  "knot_transport_key.age".publicKeys = [ recovery ] ++ dnsServers;
  "dns_voidspace_antibuilding_tsig_key.age".publicKeys = [ recovery ] ++ primaryDnsServers;

  # PGP private keys
  # For 2D53CFEA1AB4017BB327AFE310A46CC3152D49C5
  "75E3331D14EB3BE00AE4F60B8239E5B969790799.key.age".publicKeys = [ recovery ] ++ workstations;
  "81EDCEC815439600DA23AB15724393D1679C298D.key.age".publicKeys = [ recovery ] ++ workstations;
  "9DF33900CF5820B18A0C66C742A691EAC28D7B14.key.age".publicKeys = [ recovery ] ++ workstations;
  "FDE63AD88CBC90D1ABFB8FDC202C18E088EB7187.key.age".publicKeys = [ recovery ] ++ workstations;

  # Systemd-homed keys
  "497a_homed.age".publicKeys = [ recovery ] ++ workstations;

  # Other keys
  "pogopeering_dn42.age".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "routedbits_de1_dn42.age".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "kioubit_de2_dn42.age".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "sebastians_dn42.age".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "adhd_dn42.age".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "larede01_dn42.age".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "echonet_dn42.age".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "aprl_dn42.age".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "lgcl_dn42.age".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "ellie_dn42.age".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "tech9_de02_dn42.age".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "stephanj_dn42.age".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "decade_dn42.age".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  # MARKER_WIREGUARD_DN42_KEYS

  "atuin_key.age".publicKeys = [ recovery ] ++ workstations;
  "atuin_session.age".publicKeys = [ recovery ] ++ workstations;

  # Hetzner storage box credentials
  "blanderdash_storagebox_smb_secrets.age".publicKeys = [ recovery blanderdash ];
}
