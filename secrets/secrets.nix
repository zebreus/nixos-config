with import ./public-keys.nix;
{
  # SSH host keys
  # The ed25519 keys are also used for geheimnix
  # 
  # Can be decrypted by recovery key and self
  # Storing the public keys in here is redundant, but it makes it easier to deploy them
  #
  # Generated with `nix run .#gen-host-keys`
  "kashenblade_ed25519".publicKeys = [ recovery kashenblade ];
  "kashenblade_ed25519_pub".publicKeys = [ recovery kashenblade ];
  "kashenblade_rsa".publicKeys = [ recovery kashenblade ];
  "kashenblade_rsa_pub".publicKeys = [ recovery kashenblade ];
  "sempriaq_ed25519".publicKeys = [ recovery sempriaq ];
  "sempriaq_ed25519_pub".publicKeys = [ recovery sempriaq ];
  "sempriaq_rsa".publicKeys = [ recovery sempriaq ];
  "sempriaq_rsa_pub".publicKeys = [ recovery sempriaq ];
  "blanderdash_ed25519".publicKeys = [ recovery blanderdash ];
  "blanderdash_ed25519_pub".publicKeys = [ recovery blanderdash ];
  "blanderdash_rsa".publicKeys = [ recovery blanderdash ];
  "blanderdash_rsa_pub".publicKeys = [ recovery blanderdash ];
  "prandtl_ed25519".publicKeys = [ recovery prandtl ];
  "prandtl_ed25519_pub".publicKeys = [ recovery prandtl ];
  "prandtl_rsa".publicKeys = [ recovery prandtl ];
  "prandtl_rsa_pub".publicKeys = [ recovery prandtl ];
  "glouble_ed25519".publicKeys = [ recovery glouble ];
  "glouble_ed25519_pub".publicKeys = [ recovery glouble ];
  "glouble_rsa".publicKeys = [ recovery glouble ];
  "glouble_rsa_pub".publicKeys = [ recovery glouble ];
  # MARKER_HOST_KEYS

  # Private user keys
  # Can be decrypted by recovery key, hosts where the user is required, and self
  # These keys should be password protected
  "lennart_ed25519".publicKeys = [ recovery lennart ] ++ workstations;
  "lennart_ed25519_pub".publicKeys = [ recovery lennart ] ++ workstations;

  # Extra SSH keys
  "w17_door_ed25519".publicKeys = [ recovery ] ++ workstations;
  "w17_door_ed25519_pub".publicKeys = [ recovery ] ++ workstations;

  # User login passwords
  "lennart_login_passwordhash".publicKeys = [ recovery ] ++ workstations;

  # Wireguard keys
  # Can be decrypted by recovery key or the respective machine key
  # Generated with `nix run .#gen-wireguard-keys`
  "kashenblade_wireguard".publicKeys = [ recovery kashenblade ];
  "kashenblade_wireguard_pub".publicKeys = [ recovery kashenblade ];
  "sempriaq_wireguard".publicKeys = [ recovery sempriaq ];
  "sempriaq_wireguard_pub".publicKeys = [ recovery sempriaq ];
  "blanderdash_wireguard".publicKeys = [ recovery blanderdash ];
  "blanderdash_wireguard_pub".publicKeys = [ recovery blanderdash ];
  "prandtl_wireguard".publicKeys = [ recovery prandtl ];
  "prandtl_wireguard_pub".publicKeys = [ recovery prandtl ];
  "glouble_wireguard".publicKeys = [ recovery glouble ];
  "glouble_wireguard_pub".publicKeys = [ recovery glouble ];
  # MARKER_WIREGUARD_KEYS

  "shared_wireguard_psk".publicKeys = [ recovery ] ++ allMachines;

  # OpenTofu provisioning secrets
  # An environment file with the B2 provisioner key
  # (B2_APPLICATION_KEY_ID/B2_APPLICATION_KEY) and the INWX login
  # (INWX_USERNAME/INWX_PASSWORD, plus INWX_SHARED_SECRET when 2FA is on),
  # the Hetzner Cloud token (HCLOUD_TOKEN),
  # and the OpenTofu state encryption passphrase (TF_VAR_state_passphrase),
  # only used by `nix run .#terraform` on a workstation. The B2 key was
  # created once (see the terraform usage message) and is not managed by
  # terraform itself; it has no deleteFiles, so it cannot destroy backup data
  # (deleting the bucket requires it to be empty).
  "terraform_environment".publicKeys = [ recovery lennart ];

  # Restic backup secrets
  # All machines share one append-only B2 application key (as an environment
  # file); isolation between repos comes from the per-repo restic passwords.
  # The bucket and key are provisioned with `nix run .#terraform -- apply`;
  # the secrets below are written by `nix run .#sync-restic-secrets`.
  "shared_restic_environment".publicKeys = [ recovery lennart ] ++ allMachines;
  "matrix_restic_password".publicKeys = [ recovery kashenblade lennart ];
  "mail_restic_password".publicKeys = [ recovery blanderdash lennart ];
  "lennart_prandtl_restic_password".publicKeys = [ recovery prandtl lennart ];
  # MARKER_RESTIC_SECRETS

  # This is secret because it contains information about the infrastructure of other people
  "extra_config".publicKeys = [ recovery ] ++ workstations;

  # Shared secret for coturn.
  # Matrix does not support a file option, but can load extra config files, so we use a config file that only sets the secret
  "coturn_static_auth_secret".publicKeys = [ recovery kashenblade ];
  "coturn_static_auth_secret_matrix_config".publicKeys = [ recovery kashenblade ];

  # Mail server password hashes
  # Generate one with `nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'`
  "lennart_mail_passwordhash".publicKeys = [ recovery ] ++ mailServers;
  "lennart_mail_password".publicKeys = [ recovery ] ++ workstations;
  "gmail_password".publicKeys = [ recovery ] ++ workstations;
  "gmail_oauth2_token".publicKeys = [ recovery ] ++ workstations;
  # n50.lat mailboxes. himmel is also used server-side by the n50 camp services.
  "n50_himmel_mail_password".publicKeys = [ recovery kashenblade blanderdash sempriaq ] ++ workstations;
  "n50_camp_mail_password".publicKeys = [ recovery ] ++ workstations;
  "n50_zebreus_mail_password".publicKeys = [ recovery ] ++ workstations;

  # VPN mail secrets
  # Secrets for the mail accounts inside the antibuilding
  # The secrets include the login to the mail server and the DKIM key for hostname.antibuild.ing
  #
  # Passwords are generated with `tr -dc A-Za-z0-9 </dev/urandom | head -c 64; echo`
  # Password hashes are generated by piping the password into `mkpasswd -sm sha-512 -`
  "kashenblade_dkim_rsa".publicKeys = [ recovery ] ++ mailServers;
  "kashenblade_dkim_rsa_pub".publicKeys = [ recovery ] ++ mailServers;
  "kashenblade_mail_password".publicKeys = [ recovery kashenblade ];
  "kashenblade_mail_passwordhash".publicKeys = [ recovery kashenblade ] ++ mailServers;
  "sempriaq_dkim_rsa".publicKeys = [ recovery ] ++ mailServers;
  "sempriaq_dkim_rsa_pub".publicKeys = [ recovery ] ++ mailServers;
  "sempriaq_mail_password".publicKeys = [ recovery sempriaq ];
  "sempriaq_mail_passwordhash".publicKeys = [ recovery sempriaq ] ++ mailServers;
  "zebre_us_dkim_rsa".publicKeys = [ recovery ] ++ mailServers;
  "zebre_us_dkim_rsa_pub".publicKeys = [ recovery ] ++ mailServers;
  "madmanfred_com_dkim_rsa".publicKeys = [ recovery ] ++ mailServers;
  "madmanfred_com_dkim_rsa_pub".publicKeys = [ recovery ] ++ mailServers;
  "blanderdash_dkim_rsa".publicKeys = [ recovery ] ++ mailServers;
  "blanderdash_dkim_rsa_pub".publicKeys = [ recovery ] ++ mailServers;
  "blanderdash_mail_password".publicKeys = [ recovery blanderdash ];
  "blanderdash_mail_passwordhash".publicKeys = [ recovery blanderdash ] ++ mailServers;
  "prandtl_dkim_rsa".publicKeys = [ recovery ] ++ mailServers;
  "prandtl_dkim_rsa_pub".publicKeys = [ recovery ] ++ mailServers;
  "prandtl_mail_password".publicKeys = [ recovery prandtl ];
  "prandtl_mail_passwordhash".publicKeys = [ recovery prandtl ] ++ mailServers;
  "antibuild_ing_dkim_rsa".publicKeys = [ recovery ] ++ mailServers;
  "antibuild_ing_dkim_rsa_pub".publicKeys = [ recovery ] ++ mailServers;
  "darmfest_de_dkim_rsa".publicKeys = [ recovery ] ++ mailServers;
  "darmfest_de_dkim_rsa_pub".publicKeys = [ recovery ] ++ mailServers;
  "himmel_mail_password".publicKeys = [ recovery blanderdash kashenblade prandtl ];
  "himmel_mail_passwordhash".publicKeys = [ recovery ] ++ mailServers;
  "glouble_dkim_rsa".publicKeys = [ recovery ] ++ mailServers;
  "glouble_dkim_rsa_pub".publicKeys = [ recovery ] ++ mailServers;
  "glouble_mail_password".publicKeys = [ recovery glouble ];
  "glouble_mail_passwordhash".publicKeys = [ recovery glouble ] ++ mailServers;
  # MARKER_VPN_MAIL_SECRETS

  # Authoritative DNS server transport key
  # Used for transfering the changed signature records form the primary to the secondary DNS servers
  "knot_transport_key".publicKeys = [ recovery ] ++ dnsServers;
  "dns_voidspace_antibuilding_tsig_key".publicKeys = [ recovery ] ++ primaryDnsServers;

  # PGP private keys
  # For 2D53CFEA1AB4017BB327AFE310A46CC3152D49C5
  "75E3331D14EB3BE00AE4F60B8239E5B969790799.key".publicKeys = [ recovery ] ++ workstations;
  "81EDCEC815439600DA23AB15724393D1679C298D.key".publicKeys = [ recovery ] ++ workstations;
  "9DF33900CF5820B18A0C66C742A691EAC28D7B14.key".publicKeys = [ recovery ] ++ workstations;
  "FDE63AD88CBC90D1ABFB8FDC202C18E088EB7187.key".publicKeys = [ recovery ] ++ workstations;

  # Systemd-homed keys
  "497a_homed".publicKeys = [ recovery ] ++ workstations;

  # Other keys
  "pogopeering_dn42".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "routedbits_de1_dn42".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "kioubit_de2_dn42".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "sebastians_dn42".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "adhd_dn42".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "larede01_dn42".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "echonet_dn42".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "aprl_dn42".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "lgcl_dn42".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "ellie_dn42".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "tech9_de02_dn42".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "stephanj_dn42".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "decade_dn42".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "zaphyra_dn42".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  # MARKER_WIREGUARD_DN42_KEYS

  "atuin_key".publicKeys = [ recovery ] ++ workstations;
  "atuin_session".publicKeys = [ recovery ] ++ workstations;

  # Grafana (monitoring host)
  "grafana_secret_key".publicKeys = [ recovery kashenblade ];
  "grafana_admin_password".publicKeys = [ recovery kashenblade ] ++ workstations;

  # Event keys
  "engelsystem_database_password".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "pretix_extra_secrets".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "mediawiki_password".publicKeys = [ recovery kashenblade blanderdash sempriaq ];

  # N50 camp keys (separate from the darmfest event above; n50campServer runs on blanderdash, but may move to a different machine in the future)
  "n50_pretalx_extra_secrets".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "n50_pretalx_admin_password".publicKeys = [ recovery kashenblade blanderdash sempriaq ];
  "n50_mediawiki_password".publicKeys = [ recovery kashenblade blanderdash sempriaq ];

  # Hetzner storage box credentials

  # Rudelshopping (Stripe key, loaded as a systemd credential)
  "rudelshopping_stripe_key".publicKeys = [ recovery blanderdash ];
  "n50_camp_admin_password".publicKeys = [ recovery blanderdash ];
  "n50_camp_openrouter_key".publicKeys = [ recovery blanderdash ];
}
