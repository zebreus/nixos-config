rec {
  # Master recovery key
  # This key is can be used to recover all secrets. Stored offline.
  recovery = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDy99rYCgf4/w8YJ1AGjlOqoLQYdc8vOzwISdaxHech5";

  # Host keys
  # The ed25519 SSH host keys of the machines.
  # They are also used to decrypt the secrets for the machine.
  # They are present on their machine and have no passphrase
  # Generated with `nix run .#gen-host-keys`
  erms = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIjV6XlMFyfQ2MVkvDp45g+yejQ5bMplGBxWs2vSw5tY root@erms";
  kashenblade = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC3mSVmxa5RyNkEeBvKQIsPvyn8bDD+kQHI4pOkHPSvp root@kashenblade";
  kappril = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE80q4TrgnlTN7ZYN/sfr0XI1dH+xHJHRlsrmECJOxMP root@kappril";
  sempriaq = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA+5O+ll6EBBW3e/ClEHKuZKyQJnHN195lkrhiKAZwVA root@sempriaq";
  # MARKER_PUBLIC_HOST_KEYS

  # User keys
  # Used to login into machines and services
  # These keys are only present on the machines I use interactively and have a passphrase
  lennart = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIBTHzLm8QMhHIo7kFAvtAFnqpspeR3L3gM8kLoG1137";

  # Borg backup keys
  lennart_backup_append_only = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEEAbjLP/4tC4+UQCytbISY+ezfEd2NhohU7a33s0XTz";
  lennart_backup_trusted = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAf6WpgqXZg5Nz5/bYaF8fd72zE3TK8FhcCnT+7OGTRr";
  janek_backup_append_only = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBg+saphG0duv0TPObtX9GRQzcz/K6nxHVkuHetMedFp";
  janek_backup_trusted = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBFuAR34VlHKrKSFysyHHvlZgkDobF72Az4iyAIqm1E6";
  janek-proxmox_backup_append_only = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEvD6Xz+LOyq8O9Vls3sOw+Zm1xFA9YGIPjBHsWrRWP/";
  janek-proxmox_backup_trusted = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINtmJswyw0hW65cSYtIJUTWWVlTcFtrIBKAPlvSmL7AT";
  matrix_backup_append_only = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOHl6VhhC44lFd8RXoR2Ms47DQYOEaDLdstWu7azOax/";
  matrix_backup_trusted = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGHFAgSn+sRu2BAozhMJqk9GWUKR8cN0mnjK+JbL0bI8";
  mail_zebre_us_backup_append_only = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMAh77FpoiwNj+7LkbCFHqOvm57btMN5rjK1jT00B0zj";
  mail_zebre_us_backup_trusted = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKCBUTAjUWmMlNOBpp2SwFICx4DKoNxiWVGfkWtPOptr";
  # MARKER_BORG_BACKUP_KEYS

  # Wireguard public keys
  # Generated with `nix run .#gen-wireguard-keys`
  erms_wireguard = "RWL8tHmZmfw70WIjx92MVWuSn/rNCz+XlMMuGAV1uAs=";
  kashenblade_wireguard = "LOTNMmJxIFJ6J+QFXX8v0VPGGf5oCfDeYBcLuwi5FQE=";
  kappril_wireguard = "7U4VLHgsJhEyWWiPyRcG6vuqeGd2tjNxScAH0OndCyA=";
  janek_wireguard = "o5Bk0O/x2UI3FS+GAMZhW40ER/o3uBbPeiw0vJPJyiY=";
  janek-proxmox_wireguard = "x/96EtoKnx/Dtgv1+aX61BXvuYYAy89p7T/MbrU7uB8=";
  janek-backup_wireguard = "FQIG2kNEnUEbFfw3oCCstqG3lWjCranGXsfCglriJB8=";
  sempriaq_wireguard = "EUtA4cXqFQ7kXKG4YSjfQn3PnVGI1kyiGvhaVPwNOCo=";
  # MARKER_WIREGUARD_PUBLIC_KEYS

  # VPN mail DKIM public keys
  # Generated with `nix run .#gen-vpn-mail-secrets`
  erms_dkim = "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAu356BxJZizelAZPYxe+8aeofh1bnCImaMrvX45EsYCom/EMJrzCAVSAMmnEBLPMOeOKOYTpAbKoPJmXL3zc5TQ0sqhMeBTwOJLrfeaMAShXXsqNZCRLcmoIKD9i6PpOL2Gpn/fquEs0JF9lSiGww2b0bV8aDhY9I+/mnhbxH65LdWZFzjVCo3p5EOgkAcxOjITG86DWS6YF/g+RTnh/cyYAq0wzIhSrwLVeJZw49l/mLleYxE3YpEQcxvJPHwhmvwne93ilC1OpDW74Ky/0o7Y2OI3i08yljogQ8FidtPPFOtbs4IVOPLxdi1sUc/TB949sMmtsgP8pnwVs6Ezyu6/DnNuvFP6LQ0tBivOI1V/vOZ3A8QlxcVSc85t8Uw0+88kX1qqjFashSQy20p3cWRuxy3gwKYj4IZarddaV9Oc7dMlGuE/MV4U/1I6pi1jdmAH6s7wXsHGcswASjurzkgw0l/Yctyl52DsE2SSQmMmrA7ug0ded55NQlTLBZXbTTSQ9GEQnBzkzdbVdK1WDD/d9BO2Xe8XYyKRUxQE+4MkjJYb0IkznU4UhtjTT8MCoUZa2ItHSc+9Eng5OCsKE+w1pjLBPSgWA7RidzHHOka5QugsEmUMQMjyE1t5SAvoi+Zb5htY9JZRhwkQEDqC1c1y1dGYqCJ3EmRQN/lxpElFkCAwEAAQ==";
  kashenblade_dkim = "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEArVR6oBTHrKfyhxk+2UJpf5GO5CvGOEUbq8Q/ab9GcUhRnc5ksvmA02f6Moe8urQ665xzF4ZxRBlCiQx23bOCW5N4VdhYkvJvaurF4NzfkgyCDSYtqW4XoFwLZ7+h7CwZiGmjUOXB5UIqkDGJ6OeiOgUGpijHTTNKL0Z/uorTjEHztx19QuQFlPcx0W5A7KvTRIvVYmnDY2Jx7fyhf9o+IGzDx7uiV9frB5NqfmL/efMamKojY2Hr/gTuZTXW95nguhA597VcRalSx9t/k+VMLbYVZmezHq2K9x1CBsHFnpjfOGhMqJIQPNbgEdj+UHjbHwhRwdx2JuJj3opycz22RlSzTKPlbP7DobCTJmT3+ZuCq4Ky+btJT7Y4Vl+J+9ekZ+f8R8FPyqLwHQdUogT04jK0LIl24JXSw5qE2neAQKw+GfwOQBzoc+494EZ0YT/WaZHzpvHphbu/g3exwg1GXMS9BgW2kyzA1wLP8Sr2k7Ja9LUaegGQtUQQJmmIpBGS9etxOJpcXGuhLCCQTRLd54GFNIqCOTXLxL8AA556j017dCLI1LOZU0XnbkCUjZzxyk1KroUdJQqx3lHZIJ7hYQ+O87fLAXromN2WIdEZcZ0SA0OEN+FB41NG2U4aNorNhSk9lOT5GdL8LBoeJJmibVMWpHGzbF2jJKrRzjqDH2UCAwEAAQ==";
  kappril_dkim = "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEApt+7gNQOoSKAn2ZwJf/VU3I1JLn/NCfxXy1DTLyM4AH3uJL7X3KaO92uKUBIg0mlXAFUbno8MVJCPDj/cs/aK1F79HGNIQ9lbtCxQGsaaBG6Z69ARTDgvtnTVxv+YyhvhlNTSvc0PQZ5z6DCwTI07323tUWsizZ85yUA9BiZuDQ1p20Abaa6W4zZj6pRuE3F+RAbcsMVipNUM1qOI67JEl5ehOLLa0aRlpYA0x1bFVF1ucuY8GvqJSOMLkutySv/lsXi7EHzL4JVI8kn3HO99QvGvqnJzKiNlOUpToULXxbLedLkSXpfE04XdsEgEGwRIQoU4KF+x57ZWl1bbDgzVGLtr8vdc50bZvzATBi5AcSZNYJTX419zR0ExYL/F0d30NuFaebF5NxBpzJRxAKBJGUPWohYbMuNpzJDc4IdMt2OybfIfEYk2AKL0sZqQHVpy9+d43Qnaw7lPPW33dbRgj1d/Jep1ML5V8rF1AJpsYzK8fb60xJvEX2BSp4uw0+Od92MQYVF1cELcdvtDWQ1yR2mo6RZOb4V4jTHPTBi0lVZ/sAFEcfrUPZ+HMaXZRxgw7KboPdirYkF/Es6u0OJKUnZTU09qUBIo8ngWMt40I69RVL6Wgvr6Aqmy8J/xzPFkbfM2ZtfDjsCzom4fHZt6VAq6z7bvAte3LEFXaVvbZcCAwEAAQ==";
  sempriaq_dkim = "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAoxdl8JiQKxxYMZwSZ2trjcNZspZTfQrntdRON6jdIrcNIcAS0UZeG5LRGR0D1+jYUOyWgSAzUoqfQDB6Gb/NwCllOL50xnOPZwejDFRvrIEQNHDkmrCGkbriinozG3RnCGZhA2AmZQXwf4N5JntKd7mHqTLr3UkHc4ULrUu8TGOdyWwBS4WBonwz7zjRQpegt6JceK/88aSGm0rSFA8MjBEhLyVyCH0ynkfWwvbGFVK3MHGWEMODVttLmqGH/6OCPgMEeuWWs2vqmA+0W2RYhAKblu1oRb8bYwNLMySuYxl8w++VPCs0+95Q1c4tu6+5eq0rshKcw6lqodWsrzHv23DhZ2qt2lgmqB0zL2tJtODYwH7yCYE/pTBd/Qy+zLh5U4G0RJyy1SYADf69dlxa75ZNhO+y2xM7A/D64MopM+s9SLxh38edcRhAKPjVQaLNcgk+7npqO7lLpI1mLw5uMpO9Hi0Oqf2pASufN5F0YToU5iR0NRXbhqPBGSP/8mheCX/oZl9YbrsUxJ+CX24Yr/gbgP7/UxfpYXlgVyc28s8mu58lRmU6yN+SZwctwPo75xruu3cdNMdtnz44DQbCjDjJ2GPeX4DFL28vMbsAEjB4a2G9TRN5bS7tuJKSqAJu6g9m0mRtCkTeyTFVHDeo3qIqnXxptm5oUxVjeOi5WcUCAwEAAQ==";
  # MARKER_VPN_MAIL_DKIM_PUBLIC_KEYS

  allMachines = [ sempriaq erms kashenblade kappril ];
}
