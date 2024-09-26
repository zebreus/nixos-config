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
  blanderdash = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILS+05XDHYEa43azXLP8HwdXSDWpuORtmk5B2ufqLe1i root@blanderdash";
  prandtl = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINjRRN2jfJ84h10EqdhbrYnDqLL0Tqr0wfWvQWPsc9qi root@prandtl";
  # MARKER_PUBLIC_HOST_KEYS

  # User keys
  # Used to login into machines and services
  # These keys are only present on the machines I use interactively and have a passphrase
  lennart = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIBTHzLm8QMhHIo7kFAvtAFnqpspeR3L3gM8kLoG1137";

  # Extra SSH keys
  w17_door = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPStVtYN/R5trr3hQSn1rLZ2bxDveTme9wtP/dpYvpG+";

  # Borg backup keys
  lennart_erms_backup_append_only = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEEAbjLP/4tC4+UQCytbISY+ezfEd2NhohU7a33s0XTz";
  lennart_erms_backup_trusted = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAf6WpgqXZg5Nz5/bYaF8fd72zE3TK8FhcCnT+7OGTRr";
  janek_backup_append_only = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBg+saphG0duv0TPObtX9GRQzcz/K6nxHVkuHetMedFp";
  janek_backup_trusted = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBFuAR34VlHKrKSFysyHHvlZgkDobF72Az4iyAIqm1E6";
  janek-proxmox_backup_append_only = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEvD6Xz+LOyq8O9Vls3sOw+Zm1xFA9YGIPjBHsWrRWP/";
  janek-proxmox_backup_trusted = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINtmJswyw0hW65cSYtIJUTWWVlTcFtrIBKAPlvSmL7AT";
  matrix_backup_append_only = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOHl6VhhC44lFd8RXoR2Ms47DQYOEaDLdstWu7azOax/";
  matrix_backup_trusted = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGHFAgSn+sRu2BAozhMJqk9GWUKR8cN0mnjK+JbL0bI8";
  mail_backup_append_only = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMAh77FpoiwNj+7LkbCFHqOvm57btMN5rjK1jT00B0zj";
  mail_backup_trusted = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKCBUTAjUWmMlNOBpp2SwFICx4DKoNxiWVGfkWtPOptr";
  lennart_prandtl_backup_append_only = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDhfgbfKLPq9ku1okz+ivR5eb78b48mZKpu0lScgokHD";
  lennart_prandtl_backup_trusted = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDg8GlQVRU4aC2oDCkDtEd5ENKMRAMtJNgWWye2Eau0Z";
  leon_backup_trusted = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHDDQCsVnX67JHU006N7v/smtzghvUC3MKA5+h+O6CDs";
  leon_backup_append_only = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHDDQCsVnX47JHU006N7v/smtzghvUC3MKA5+h+O6CDs";
  void-mendax_backup_trusted = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPnNyOCX+PopTHuNrfBwEmPM7FC6oM7nFgW/2tvW7ddT";
  void-mendax_backup_append_only = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAxW+Kyt3spM3uAtM8NwBYcplZ+OsZ1drHklGGmAiI0m";
  void-hortorum_backup_trusted = void-mendax_backup_trusted;
  void-hortorum_backup_append_only = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICPoR70IvFV9DDI00e6PmILxdGo0n415UUSRMeNhzvL7";
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
  blanderdash_wireguard = "yFx4AJXOdeuJWXh49DX2/ZO49hIanWJb0Jskuo4p63Y=";
  prandtl_wireguard = "nAN30SXneQcSandzacBYO8cqIA0e2z+5ejukDzruDGo=";
  leon_wireguard = "rZcYbQkYucVu/fPnAK6ciB3OiwAvlddmsxoaC+Apc0I=";
  trolltop_wireguard = "iUGYUvG5vOBWkiLedMjSAnRcqtYoP2cwocarfRbgf0M=";
  void-mendax_wireguard = "0000000000000000000000R00000000000000000000=";
  void-hortorum_wireguard = "0000000000000000000000R00000000000000000000=";
  # MARKER_WIREGUARD_PUBLIC_KEYS

  # VPN mail DKIM public keys
  # Generated with `nix run .#gen-vpn-mail-secrets`
  erms_dkim = "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAnyq+y/+ZmWK/q8G9BHTuRa3wh418L3X0fWX3sABHFwQClIiaYZ2U+lEcsaSkPUBvFmf1cJBz9ejg4qzprNGFUBms6aYPLH8Zknc6BvKDCafqSKiUzPiZTiYHOE27okfnWgYoaVet3CQq9JDvWWCyJ33ywGG7lToT/o5f2iC4r04n52KSdBvy4lCaIQgWWfS5UzJuZNjXLCQgex4ZMtcLnBML4dg0OkIlm7VGrqoOhA198W079mg23Jk1lhbtcBC6ZaEw8LbzkOaljpZKd9vJu/rh5/B3hp1T2P+TaHad/+gSP9KaGhGfTWMs5atc93iVRITfAkrsT1I6DolsDEveSSVjivNokt4aUhzHwM7qQDwjKcE0hBVBiLQ1jQJiqJwNIPs08Cxg76zOI5iK9odK7vO9HJu7g60pHrcywNpm+41bfbxIBuLT1t5XO9LO51ahMF1gubUFxfBwRRWAk7rYmuKogyAabfsOeiV8FO/nMWJ/AWfjEG/c7n7gCuNNfIrAhasjAbvfApOXQT+t0QHgrV0u/Clu76IE5nBQlc+erJdmZ3Yci5oxuH5cAX4P+8J9q+rNHa7GWKruVOchiWRQ2Yqf+wKluA0B7vYUhaBUN6T8Vrv08w2dX111jWWuwJtMzIDM7CUYUruK/5qBbhp/jaD5bV0b7DGH1bHGBi03Bt8CAwEAAQ==";
  kashenblade_dkim = "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAogIYRwcNXEcjHLY0e0mnwnSqbs3cN39bNk9C8c+gHwGbsQE9JnQAgqgrqC8p2fV0zB1YGpPQ/x+mZY0aaOQhskR5b9rJcdjlvAajmP9F2nuuhU74EvtX9sqeS9mc5jWrsWkADxw7B0fuFun1wEyvFCyiAemAMvuGdRj9oqB61YW0S2wU7ffNqU5h3yPBUey8ZYFZQZpGlHeoGvcKFrD3FZk8HvRQ6DoOleE9IpWw7dd648dOoz+LYlTzeI6SK5w/AQ8T8iaGYH72GEPy7eDPNOZ/aev5PLZTfREUaLTPx+UCT4FNwedLfzNqGv7pyvwD2WP3oQUqMbI0602AJUMcJmSC2jwdKXomDlS4vBBBcwd1DWxsulwd6vXpDJIOuZQ30AoYKSa49py8ve+5dheaR99B8zhUWEBtEko3eRL7aLcgm7XZn5t27xNug8gmgl8h14w4bTmBG/WjJtyLZhVgZ8ZYfo0VV3UCnVWXqVWYTXcf14jQkh+pr85aiDLqmiSbpDrrRVs4VQkXqTx2d0bSguGJgU1kN/1XW+aKI9/2cuwRItjTN9vgCrQrMZeWtyMc2pmZAgAARhzkl60sKFqHdSwht7PGssVp8DrpyLKdHdHlQvty1gd/W1v4hFaSQj+pD6BGG8VZyB3Mbi3B+0uvRev2daSYUUyUh3T/rCvIXeMCAwEAAQ==";
  kappril_dkim = "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAkJFTqTwFdcqVC8rJZWAqI8YXOpkYlf7oBqnnJPBijMis4Z0fA7fzEGkZwdYUMehtAdeRBbSio6+kox3f7fBJKWuEKhFMxJ3UPaxY6xa3Xah7pcvjshnpqJ1BSG5tgP7aYZGHbd0p0XYDLR3+iIt1vZvqaL7jsEQRCfm9qYp+77EpIzd7w6VKOHazTjKtrwJvRhHY4rch/7FDhZZ8IhOrHF/SpVx/iOUGQZYtfn9dfq4PHsORCU125VFcopxlBmjD+MJobOdHeXZyyCjuuKFZ9LvfORf2kUsraOSIDvP3w80vSAfEF1+bS1Tf3Rr1S8hMb9vBrGsskIj104QHu2WYWFXtDygXNfxARvSskpTnQrMHlYWeDLJa4i5nqD33Md1Ec0gjKEqZLEmofhBVHhVGBOxX7EcEc1C6RiXwjeKWxGLsBs3QfEyPrcuDlSPKqIigos2Zg7eoH0PtcJqtdom0CFTnCHOTMiR8sVhiRZAei+YDu/Op58xUPVgVEfE2oVeN6OmMzlR5qYH50/ak+yJnuQ0oUu0FhzmSd9vOt5NBlMRRx1o2dTuNsulGK07kuOfMzq/T5A0h1xUFTi48Go6pFMQNLEx9XJ0s3NpYwluFZoxtvYRStCEQJ08EaTqYbfwSVfbOl/J/K92XAFwTs63dA6VvaaA2KkEFWUCL/CY8JdkCAwEAAQ==";
  sempriaq_dkim = "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAykhj41xlO/la1im61lxdAF5+pSTpjna+8ciSCrAv2Snjc8Lx1DHzdevZ3gU/GEEvLFBBp673SD9Ccoq4Jd4TFI/j7+Nhzt+fKfdQpJpIhiuBAFB02WeYwLPo32sXjtp87nP1DVQjthFchPlcXL4u8RSH75Dt6TKzUHJtXAGBDdrys/buvWpqpctvJ6FTCp45/RjHOcLPc6VZbWWoL7+X88tJ+7jnxrJRkuV1VvyTlfHPz1bEibFFgz76ZocN56pgsoMtAnGON30inbyBysyiLu5jRWY56LCV6zB80n6hHUy08uZzz8dFrxOF6R3unDhTHZalkITcjJKx5iuoxhCqfhUIdH0JwKRTEhIQK5o0MaYjAGbMqQ7C5hOjY4tv0Xk6N0oYv6Km5B1iA+uQf+agr3WNswEhp0b4f69pbm9LbKoOqWHXfPxkN6rRj8EYwKm3D6nV8dZhQHpF+Q4cK3zMsgRt0ph/hOVXs++G6nu7kAF+LAgJ+Cew60h8PzZkyr/f3dPCD18cdXG9egNT/RfASQjFZpzEgPzVBNot/+zQMLcEKtBCgL8tWm/I841HFO5RKgGyA9azDFRuKNqqthScpUjMW0bLyjQE/VAgrnbV5q0Dt1Jhwa27tA3so285C7ui7gChGDM4jGQHbwdfkmHkaJdiuAQJmrQkHLxtYqjxJ0MCAwEAAQ==";
  zebre_us_dkim = "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAqdfp7akzmZDs1Kdswt4CVaz8VxIrlI95XVA+MtYToWAWNKpYuyRyRDb2HjswX7uWjXMTG4fvU6DiX3k0/Mn0d+KnOjQrQaq9NwliRsB4Ovd0geax4HyCS6in/I9UcLjPYyKw185R/ukQiM3uW7687ETQEL+HAYdw6lbpDhSujVY7pDdAXDh2BDlK+PC0+OuhyT1Qn6arI+gvPTTnnN4tXJMk2L3BnofvM8OcTKcVfygm42RzUCHRQzXqbpIC+oag9fGXWCzJZu/BKUsVoWTHjPcjGkP4/8M44IXZxnGoDAxyYr0Le8YGnhNK9uD6PbF8IHhhlwrey/5MERwSVHvl0J5FWFzvs/oojVuZxhLQ8zgiakw7ig4Mvzf5KqPjipeVkDZFmKB5+z3Ug/7XNx6djwm7TMRn3NfYyaeOq/TwoWPSONC2EZ5uKqFHEsC+4MLJVv6GOMlkhAfyBYJ95eR0AxZ/R9x0vkWhX8bamVWMtQeS75gGL7Zq+zdwhys+2pko20d12S9Wl40185BverZhZZYvANSUavzekp9JG0wy6sU/wN+xQmi6bWV3Jdl0QIWTBC1C25caQ0K8lRJrYmDRU0sxGfmLTO8EOnhYEBUvAEfnRYIIfRVQMaBDzMCTK0AEnXwYIoK+vQBJ7Mq69L1E40YFE/r17htjy5/fY9pdrxsCAwEAAQ==";
  madmanfred_com_dkim = "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEArbK3qyg4vVbZVDwA+oHEMxuHNS+7mp7gcz6v1ZuBukPPlSdLoTepRuJy2X6+8kt48YJKg1Mn0V5voZuInWlcnWOY+O+j0T1qCbuaTkIcUyRg5oWiYm6IhSGxc9XLXw4YMOobSP+5ALQ3YF1Z07uX/b8K+sCFE/eY9J/KdBHQxbKaeB9zrCvINBoewK17fJqQMkMdSsn0Ucca0AEemHB7y6VxlASnHxMS9iDiOekTZ3QjwkMbGwGlJBU0yHxGCaluF2D24NXiK8hco7tnHQF2QVnF80lfoIxraxgOKJlrC+Y6g49cKy8JLw4QBPBWcmd5ZYAWfo6xOpZtwzaUsK5Bidd4PQxhP3g4LHUM3kndIZQ7KiF7Hr5VdCCdhOP8Af1TOib0lw9FkcQ/twIZQ0I7VODq6nY9Esl4LZFOepybIw9UGJI+29jcXiZiFGG1tdf6oE+TGZ5NKw5fza2HvRh08wc444PriYQITF/12D2V6MzJ15QmmGA/Z7lp0EnZ/V8bfYxW6GuKFuScmAWbC4OUg1LZnndjuqzXFNwVDj5Uvozsmy2FObeKsxNTagekd84v6So1Dy2p01JpN8RL5uZZ6tqOphdR+V/s4zDcz/yAYmII6GO+Sa/oQyesdwB8EBnr8pH8RXP0Cbt9cnfoVkmwM4YJho8xYWcc9tlwCg6ADYMCAwEAAQ==";
  blanderdash_dkim = "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEArzjSzAYdA9QxN+8FvSTs2SAjXbsdu59Yl7aDRBVo6/oMdLeqVhIFGVyo8v04V9F/OLF0h5t3pyIgS74aUU2q7BgnW+zIMQWrv3kblO14R3nzGWL2FYDqy+uoiAqN/DY9R0VL4MCcuFa6oAX6Fkxh8zbV7Y6VxCH5pcOB6/uVAQiYvJkqn+7O7MfnZ+ezoq+850V7Nxgz6K9f/5aHCYeaHE9kHV17OACsr22JYYU/I3n6vGaijFnQvNRfbEIS0YhHy6odXDHI9hM1hiABUlu6Mh2wcs3rcX/LaRwmrBD7ilFl8xuF7UM60EOZgxywdeWHD51Sb81bC43tIoCwMkTE73rr8Z+fJTqCfcd/nlz8SrJvnPgxhjQJCS0/NwbUfkI90LhOtYwrmW742aM76hkpZP4V4styvcj1kDBsJzgg5lu86fUcGvPEquH1nRTD1knsBwpZCcf3VWJiOAPO0qwN50gRhvdA3GvtAIEg4bfnKULVdZstUkQ+qV2xK5FxYduYvNPG0MivJgH6TEQtwyjifp4dyAxK6+9QEEXgECRpO/ZMLyDeRCfb8Tsu1en7gJadQ+99gQ8bLGKKzOPYjOKhyUofeleKhU6Z+09fDoTIZHfdPh/Xsg6vZW6Wm6xCxIUTHWykabPkSVtsfwWgn3+1A/Ol95c0EPoFNMrEtnM4KjkCAwEAAQ==";
  prandtl_dkim = "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA0noX/YPgYDMJrAVxkTHsM9wChmuqos+B9myXYrBtif4xh2LzMnZkaJxpCjjJA3j8lCY/Uxo+r4gKdpo0Dn9j5orAT/aMnCakVEwbEi4q+sQR0UZx55qOhR6WDQk6POO5vVkA5fAl7y1tCP/kkWw759TfSuRvIlATE0ia828aWq9nRch7Vn/5OEwpBKHRWMdqahLOcSLnGdyr2C5diKGUoUNSE/z2hvcBMMV5Q1qXSZVk/Xqz/hwcMEsDgYxg0v9q4a9wG0z9cSMMKnxjP/JKISYTZuiF9PxHz7Atchs8W7IgVliDqJiEFXRUFEaDaJxTGNRh035qIr2RoB2ReehRzzNNw5nXxUTTbkScDmK1KbnbN1YBHsIIF8krDLCvv9xZei1eph3+jIBTJ0Gq7BWLu9knTwGJbRMBFMQduog3Y7RKAf80T4IFNOJHKuqF2tMhhEfRAzlzDWqhgvpHkhKIr6ANM4UU5Fu8OZVHjWw6msRGayFk2vNB/M8hdKnwE65VI1gtKmZR1I8oSO9cG2j9xTj4V7J+hfQkZgvLDnGaoQeLM+uGAxZkYtqq2qR+Ie7tiTGPuJGg1qPkbSboRCa7ItcOV1DsRjQK7jPEXT50hXExHHV0iPjmtVydy3UPyWZEg8CZsDFy2ntzhHtoarv3vLh201s38Ie2oI7U/Lm3SfECAwEAAQ==";
  antibuild_ing_dkim = "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAwn99X8VDmZPP0nwdfhvTSaQzpqa8qSLhINKCvbz3AF2Dih6OlWi0On0wkv7lmO2Ju4gWwvRrIeSnChzZQprRfnNKq6DQ0Eh4fljdufppNkAh3tjB3KR4jIOFCVqFZOzYCSyoz4u0Qe5NTjfbjOU7zhyf/48MuvU5PtEUk58ht/UPJV7fxK7tksvKEw7RYYKyh4IaaCG7iHW7BNUU50zDTeQtvmDGgN9ymBdnZkRb7SNbSclHXBp3cWCvPGOK3BpZ8rG0aoeBblENcY9FB3LGLcGqZ5SHrvQOgnQBOlybGLw5upCvHKR0OOfbV1V0rbsCIFhwaoAJwvg+x7pgW+rjo0mE4nVGSjFoLr4tPSyzGxXyYjYWmM4RBeek1Sl8T7RKpO9Vv928WSzBcQT4YkdeHCDaYliwJtQ2Z/mkGV550BTMlcQllw5KfDYMugdG+ijGA0P7qJ4IEqj+JMmADKUjakb2EtT+eMgRy9b7to2nveSZsEEXIbgJZhfbt6nwste+QRMrxn6NfEE2FyjwjcGXKZ085SC4iPcyJM4o++nPLI1fzli0Q1p1YaxSvl+D8W8tQjdtf29amvhj+kREpSS+KIoCayJKh9dODhV26Ywi6pFxcQorhtFERRC0Rk6G0IBEiVldGkFxSQEsGJMbpYEp2+jQfjz3vTdHxHgaD3qB/58CAwEAAQ==";
  # MARKER_VPN_MAIL_DKIM_PUBLIC_KEYS

  allMachines = [ prandtl blanderdash sempriaq erms kashenblade kappril ];
  workstations = [ prandtl erms ];
  dnsServers = [ kashenblade blanderdash sempriaq ];
  primaryDnsServers = [ blanderdash ];
}
