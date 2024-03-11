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
  erms_dkim = "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAnyq+y/+ZmWK/q8G9BHTuRa3wh418L3X0fWX3sABHFwQClIiaYZ2U+lEcsaSkPUBvFmf1cJBz9ejg4qzprNGFUBms6aYPLH8Zknc6BvKDCafqSKiUzPiZTiYHOE27okfnWgYoaVet3CQq9JDvWWCyJ33ywGG7lToT/o5f2iC4r04n52KSdBvy4lCaIQgWWfS5UzJuZNjXLCQgex4ZMtcLnBML4dg0OkIlm7VGrqoOhA198W079mg23Jk1lhbtcBC6ZaEw8LbzkOaljpZKd9vJu/rh5/B3hp1T2P+TaHad/+gSP9KaGhGfTWMs5atc93iVRITfAkrsT1I6DolsDEveSSVjivNokt4aUhzHwM7qQDwjKcE0hBVBiLQ1jQJiqJwNIPs08Cxg76zOI5iK9odK7vO9HJu7g60pHrcywNpm+41bfbxIBuLT1t5XO9LO51ahMF1gubUFxfBwRRWAk7rYmuKogyAabfsOeiV8FO/nMWJ/AWfjEG/c7n7gCuNNfIrAhasjAbvfApOXQT+t0QHgrV0u/Clu76IE5nBQlc+erJdmZ3Yci5oxuH5cAX4P+8J9q+rNHa7GWKruVOchiWRQ2Yqf+wKluA0B7vYUhaBUN6T8Vrv08w2dX111jWWuwJtMzIDM7CUYUruK/5qBbhp/jaD5bV0b7DGH1bHGBi03Bt8CAwEAAQ==";
  kashenblade_dkim = "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAogIYRwcNXEcjHLY0e0mnwnSqbs3cN39bNk9C8c+gHwGbsQE9JnQAgqgrqC8p2fV0zB1YGpPQ/x+mZY0aaOQhskR5b9rJcdjlvAajmP9F2nuuhU74EvtX9sqeS9mc5jWrsWkADxw7B0fuFun1wEyvFCyiAemAMvuGdRj9oqB61YW0S2wU7ffNqU5h3yPBUey8ZYFZQZpGlHeoGvcKFrD3FZk8HvRQ6DoOleE9IpWw7dd648dOoz+LYlTzeI6SK5w/AQ8T8iaGYH72GEPy7eDPNOZ/aev5PLZTfREUaLTPx+UCT4FNwedLfzNqGv7pyvwD2WP3oQUqMbI0602AJUMcJmSC2jwdKXomDlS4vBBBcwd1DWxsulwd6vXpDJIOuZQ30AoYKSa49py8ve+5dheaR99B8zhUWEBtEko3eRL7aLcgm7XZn5t27xNug8gmgl8h14w4bTmBG/WjJtyLZhVgZ8ZYfo0VV3UCnVWXqVWYTXcf14jQkh+pr85aiDLqmiSbpDrrRVs4VQkXqTx2d0bSguGJgU1kN/1XW+aKI9/2cuwRItjTN9vgCrQrMZeWtyMc2pmZAgAARhzkl60sKFqHdSwht7PGssVp8DrpyLKdHdHlQvty1gd/W1v4hFaSQj+pD6BGG8VZyB3Mbi3B+0uvRev2daSYUUyUh3T/rCvIXeMCAwEAAQ==";
  kappril_dkim = "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAkJFTqTwFdcqVC8rJZWAqI8YXOpkYlf7oBqnnJPBijMis4Z0fA7fzEGkZwdYUMehtAdeRBbSio6+kox3f7fBJKWuEKhFMxJ3UPaxY6xa3Xah7pcvjshnpqJ1BSG5tgP7aYZGHbd0p0XYDLR3+iIt1vZvqaL7jsEQRCfm9qYp+77EpIzd7w6VKOHazTjKtrwJvRhHY4rch/7FDhZZ8IhOrHF/SpVx/iOUGQZYtfn9dfq4PHsORCU125VFcopxlBmjD+MJobOdHeXZyyCjuuKFZ9LvfORf2kUsraOSIDvP3w80vSAfEF1+bS1Tf3Rr1S8hMb9vBrGsskIj104QHu2WYWFXtDygXNfxARvSskpTnQrMHlYWeDLJa4i5nqD33Md1Ec0gjKEqZLEmofhBVHhVGBOxX7EcEc1C6RiXwjeKWxGLsBs3QfEyPrcuDlSPKqIigos2Zg7eoH0PtcJqtdom0CFTnCHOTMiR8sVhiRZAei+YDu/Op58xUPVgVEfE2oVeN6OmMzlR5qYH50/ak+yJnuQ0oUu0FhzmSd9vOt5NBlMRRx1o2dTuNsulGK07kuOfMzq/T5A0h1xUFTi48Go6pFMQNLEx9XJ0s3NpYwluFZoxtvYRStCEQJ08EaTqYbfwSVfbOl/J/K92XAFwTs63dA6VvaaA2KkEFWUCL/CY8JdkCAwEAAQ==";
  sempriaq_dkim = "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAykhj41xlO/la1im61lxdAF5+pSTpjna+8ciSCrAv2Snjc8Lx1DHzdevZ3gU/GEEvLFBBp673SD9Ccoq4Jd4TFI/j7+Nhzt+fKfdQpJpIhiuBAFB02WeYwLPo32sXjtp87nP1DVQjthFchPlcXL4u8RSH75Dt6TKzUHJtXAGBDdrys/buvWpqpctvJ6FTCp45/RjHOcLPc6VZbWWoL7+X88tJ+7jnxrJRkuV1VvyTlfHPz1bEibFFgz76ZocN56pgsoMtAnGON30inbyBysyiLu5jRWY56LCV6zB80n6hHUy08uZzz8dFrxOF6R3unDhTHZalkITcjJKx5iuoxhCqfhUIdH0JwKRTEhIQK5o0MaYjAGbMqQ7C5hOjY4tv0Xk6N0oYv6Km5B1iA+uQf+agr3WNswEhp0b4f69pbm9LbKoOqWHXfPxkN6rRj8EYwKm3D6nV8dZhQHpF+Q4cK3zMsgRt0ph/hOVXs++G6nu7kAF+LAgJ+Cew60h8PzZkyr/f3dPCD18cdXG9egNT/RfASQjFZpzEgPzVBNot/+zQMLcEKtBCgL8tWm/I841HFO5RKgGyA9azDFRuKNqqthScpUjMW0bLyjQE/VAgrnbV5q0Dt1Jhwa27tA3so285C7ui7gChGDM4jGQHbwdfkmHkaJdiuAQJmrQkHLxtYqjxJ0MCAwEAAQ==";
  # MARKER_VPN_MAIL_DKIM_PUBLIC_KEYS

  allMachines = [ sempriaq erms kashenblade kappril ];
}
