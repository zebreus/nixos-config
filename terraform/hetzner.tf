# The Hetzner Cloud servers. Only the cloud side is managed here; the NixOS
# on them comes from this flake. Both were installed from an ISO, so their
# image is null on the Hetzner side — the required image attribute is a dummy
# and must stay in ignore_changes, otherwise tofu would replace the server.
#
# Both were rescaled to their current type with the original 40 GB disk kept
# (smaller than the type's default), so keep_disk must stay on: without it a
# future rescale would grow the disk, which is irreversible and would forbid
# downscaling.
#
# Credentials come from the HCLOUD_TOKEN environment variable (from
# secrets/terraform_environment.age).
provider "hcloud" {}

resource "hcloud_server" "kashenblade" {
  name        = "kashenblade"
  server_type = "cax21"
  location    = "nbg1"
  image       = "debian-12"
  keep_disk   = true
  backups     = true
  shutdown_before_deletion   = false
  ignore_remote_firewall_ids = false

  lifecycle {
    ignore_changes = [image]
  }
}

resource "hcloud_server" "blanderdash" {
  name        = "blanderdash"
  server_type = "cax31"
  location    = "fsn1"
  image       = "debian-12"
  keep_disk   = true
  backups     = true
  shutdown_before_deletion   = false
  ignore_remote_firewall_ids = false

  lifecycle {
    ignore_changes = [image]
  }
}

# The static public addresses; machines.nix (staticIp4/staticIp6) and the
# glue records in inwx.tf must match them. Names and auto_delete mirror the
# existing IPs; note auto_delete means deleting a server releases its
# address.
resource "hcloud_primary_ip" "kashenblade_ipv4" {
  name          = "kashenblade-ipv4"
  type          = "ipv4"
  assignee_type = "server"
  assignee_id   = hcloud_server.kashenblade.id
  auto_delete   = false
}

resource "hcloud_primary_ip" "kashenblade_ipv6" {
  name          = "kashenblade-ipv6"
  type          = "ipv6"
  assignee_type = "server"
  assignee_id   = hcloud_server.kashenblade.id
  auto_delete   = false
}

resource "hcloud_primary_ip" "blanderdash_ipv4" {
  name          = "blanderdash-ipv4"
  type          = "ipv4"
  assignee_type = "server"
  assignee_id   = hcloud_server.blanderdash.id
  auto_delete   = false
}

resource "hcloud_primary_ip" "blanderdash_ipv6" {
  name          = "blanderdash-ipv6"
  type          = "ipv6"
  assignee_type = "server"
  assignee_id   = hcloud_server.blanderdash.id
  auto_delete   = false
}

resource "hcloud_ssh_key" "lennart" {
  name       = "lennart@t15g"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDSzz3v/BNDgCZErzszVq064goCNv3KiQzt97DVXHFMg3VeYDv1okVXD2/jrf1Hxvjnh1LVeMN8vMbCp3jODYSI/nsXFqF2Br57QPN96fczUu/ew82iE3jlq5N0ZIMx9DUgIdvGBkj1Oj1W47K17bdE1+7EV03xwsWDVCVJid+ZtoSIF86IUZBaEmR29X/dsHrkTYMYjP0cCg4w8ihSQ1YBo//qI2KDS9ynj62vcOLEB67vKFX7U3Z7cmvYHWGJmSzQKwKsVTTOBGjhAumJPzSvo0ZdwinvZyKNq5ZPr3r9YEDKjzuwReKJSIse0+frbver3fEhD0y00pHD1QNij93231w7HfpSNT5MymdIpV4MKC/cdVbd598+p32CFur+iXQZfo7IkPH4hi7o66elv4yJF8Tk3w3bIOX7uCBL3+wiHkIQ/hq3dZ2slOA9J13uVfMSr/FVJRM8NnIB0kWdjzbYWYMJEDUEjmL6eJizIizL6JThstaYSXX0C/k1kpelKUs="
}

# Reverse DNS for the mail server on blanderdash; mail delivery depends on
# the PTR records matching the HELO name.
resource "hcloud_rdns" "blanderdash_ipv4" {
  server_id  = hcloud_server.blanderdash.id
  ip_address = hcloud_server.blanderdash.ipv4_address
  dns_ptr    = "mail.zebre.us"
}

resource "hcloud_rdns" "blanderdash_ipv6" {
  server_id  = hcloud_server.blanderdash.id
  ip_address = hcloud_server.blanderdash.ipv6_address
  dns_ptr    = "mail.zebre.us"
}
