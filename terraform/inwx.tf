# Registrar side of the domains held at INWX. The zones are served by our own
# authoritative nameservers (meta.services.dns in machines.nix), so INWX only
# holds the registration, the NS delegation and the glue records for the
# in-bailiwick nameservers under antibuild.ing.
#
# Credentials come from the INWX_USERNAME / INWX_PASSWORD environment
# variables (from secrets/terraform_environment.age). If the account has TOTP
# 2FA enabled, also set INWX_SHARED_SECRET to the base32 TOTP secret there.
#
# Domains still being transferred to INWX are imported once their transfer
# completes, not created:
#   nix run .#terraform -- import 'inwx_domain.domains["<domain>"]' <domain>
#
# The knot-served zones are DNSSEC-signed and most have DS records at the
# registry (currently all except darmfest.de and chaosdarmstadt.de). If a
# transfer drops them, republish the KSK
# (`dig DNSKEY <domain> +short`, flag 257) with an inwx_dnssec_key resource
# (domain, algorithm = 13, public_key).

provider "inwx" {}

locals {
  # The one INWX contact (Lennart), taken from the imported domains.
  contact = 1015223

  # Must match meta.services.dns in machines.nix: ns1 kashenblade,
  # ns2 blanderdash, ns3 sempriaq.
  glue = {
    "ns1.antibuild.ing" = ["167.235.154.30", "2a01:4f8:c0c:d91f::1"]
    "ns2.antibuild.ing" = ["49.13.8.171", "2a01:4f8:c013:29b1::1"]
    "ns3.antibuild.ing" = ["192.227.228.220"]
  }

  domains = toset([
    "antibuild.ing",
    "chaosdarmstadt.de",
    "darmfest.de",
    "essen.jetzt",
    "rudelb.link",
    "wirs.ing",
    "zebre.us",
  ])
}

resource "inwx_domain" "domains" {
  for_each = local.domains

  name        = each.key
  nameservers = keys(local.glue)

  period        = "1Y"
  renewal_mode  = "AUTORENEW"
  transfer_lock = true

  contacts {
    registrant = local.contact
    admin      = local.contact
    tech       = local.contact
    billing    = local.contact
  }
}

# Glue records for the nameservers that live under antibuild.ing itself.
resource "inwx_glue_record" "nameservers" {
  for_each = local.glue

  hostname = each.key
  ip       = each.value
}

# The KSKs of the knot-signed zones; publishing them makes INWX submit the
# matching DS records to the registries. The keys never rotate (ksk-lifetime
# is 0 in the knot policy) and were fetched from the zones themselves:
#   dig +short DNSKEY <domain> @ns1.antibuild.ing | grep ^257
# The digests were verified against the DS records already at the registries.
locals {
  ksks = {
    "antibuild.ing" = "7zyez0mNeD+Hty2+F0Qy7hFHD0rEGNvJrzU2UxhHqaQNXtihN7cfkh/TBg/ohvQ+OKDHaMXS+YvfFMPsVMkg5Q=="
    "darmfest.de"   = "ve3Zm51n59BDT29RAp4QF9NOZMbRZqP4PG2oQV4DaKHZpnflhMRoi07wi5/jJHd54QKi/IgB4i6zaTCukY9HoQ=="
    "rudelb.link"   = "ld7zWej7FMkpPfY/Q4F2q+qqlKex/4/ImlX/hNntDrwc2t2MpAfh/Sbrmt+ZsIqH8Hr4QxXy2Nu7Wrm62ni8Cg=="
    "wirs.ing"      = "dz9CO/0wyZrCs776ss+jOeSgth2Fpj65QM+ZodDtBhEk3DrbEWJ0nfRGpRJn1OmBfVcU51AruN6T047nPSRt6A=="
    # Not yet transferred to INWX; uncomment after their import.
    # "essen.jetzt" = "S+nCCDudgsf//kMBcsjL41n3XYHJjztWeyM/3uYB9UouCMTFY3+yC+HdKNhRaqbZOhbF2TmeqtrN8uG6OQCcig=="
    # "zebre.us"    = "OLZUOnog7zegeUT6n+i+mUiNqouspbLcy+6ywAo+7+C1waNzHQ58mY5bRXXoWxe2JBJQe6Edh/y+dr2CWtO9lg=="
    # chaosdarmstadt.de: add once the zone is deployed and signed by knot.
  }
}

resource "inwx_dnssec_key" "ksk" {
  for_each = local.ksks

  domain     = each.key
  public_key = each.value
  algorithm  = 13
}
