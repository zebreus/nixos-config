let
  publicKeys = import ../../secrets/public-keys.nix;
in
{
  users.users.lennart = {
    isNormalUser = true;
    description = "Lennart";
    extraGroups = [ ];
    openssh.authorizedKeys.keys = [
      publicKeys.lennart
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDSzz3v/BNDgCZErzszVq064goCNv3KiQzt97DVXHFMg3VeYDv1okVXD2/jrf1Hxvjnh1LVeMN8vMbCp3jODYSI/nsXFqF2Br57QPN96fczUu/ew82iE3jlq5N0ZIMx9DUgIdvGBkj1Oj1W47K17bdE1+7EV03xwsWDVCVJid+ZtoSIF86IUZBaEmR29X/dsHrkTYMYjP0cCg4w8ihSQ1YBo//qI2KDS9ynj62vcOLEB67vKFX7U3Z7cmvYHWGJmSzQKwKsVTTOBGjhAumJPzSvo0ZdwinvZyKNq5ZPr3r9YEDKjzuwReKJSIse0+frbver3fEhD0y00pHD1QNij93231w7HfpSNT5MymdIpV4MKC/cdVbd598+p32CFur+iXQZfo7IkPH4hi7o66elv4yJF8Tk3w3bIOX7uCBL3+wiHkIQ/hq3dZ2slOA9J13uVfMSr/FVJRM8NnIB0kWdjzbYWYMJEDUEjmL6eJizIizL6JThstaYSXX0C/k1kpelKUs= lennart@erms"
    ];
    home = "/home/lennart";
  };
}
