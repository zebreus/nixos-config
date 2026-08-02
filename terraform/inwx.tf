# Registrar side of the domains held at INWX. The zones are served by our own
# authoritative nameservers (meta.services.dns in machines.nix), so INWX only
# holds the registration, the NS delegation, the glue records for the
# in-bailiwick nameservers under antibuild.ing, and the DNSSEC keys.
# lostposition.win is at INWX too but deliberately not managed here.
#
# Credentials come from the INWX_USERNAME / INWX_PASSWORD environment
# variables (from secrets/terraform_environment.age). If the account has TOTP
# 2FA enabled, also set INWX_SHARED_SECRET to the base32 TOTP secret there.
#
# Domains still being transferred to INWX are imported once their transfer
# completes, not created:
#   nix run .#terraform -- import inwx_domain.<name> <domain>
#
# Contacts: each registry only supports a subset of the four contact roles
# (admin-c exists nowhere anymore, billing only for .de), so each domain
# lists exactly the roles INWX persists for its TLD.

provider "inwx" {}

resource "inwx_domain_contact" "lennart" {
  type           = "PERSON"
  name           = "Lennart Eichhorn"
  street_address = "Strasse 10"
  city           = "Berlin"
  postal_code    = 10115
  country_code   = "DE"
  phone_number   = "+49.123456789"
  email          = "lennart.eichhorn+inwx@gmail.com"
}

resource "inwx_domain" "antibuild_ing" {
  name = "antibuild.ing"
  nameservers = [
    "ns1.antibuild.ing",
    "ns2.antibuild.ing",
    "ns3.antibuild.ing",
  ]

  period        = "1Y"
  renewal_mode  = "AUTORENEW"
  transfer_lock = true

  contacts {
    registrant = inwx_domain_contact.lennart.id
    tech       = inwx_domain_contact.lennart.id
  }
}

resource "inwx_domain" "chaosdarmstadt_de" {
  name = "chaosdarmstadt.de"
  nameservers = [
    "ns1.antibuild.ing",
    "ns2.antibuild.ing",
    "ns3.antibuild.ing",
  ]

  period        = "1Y"
  renewal_mode  = "AUTORENEW"
  transfer_lock = true

  contacts {
    registrant = inwx_domain_contact.lennart.id
    tech       = inwx_domain_contact.lennart.id
    billing    = inwx_domain_contact.lennart.id
  }
}

resource "inwx_domain" "darmfest_de" {
  name = "darmfest.de"
  nameservers = [
    "ns1.antibuild.ing",
    "ns2.antibuild.ing",
    "ns3.antibuild.ing",
  ]

  period        = "1Y"
  renewal_mode  = "AUTORENEW"
  transfer_lock = true

  contacts {
    registrant = inwx_domain_contact.lennart.id
    tech       = inwx_domain_contact.lennart.id
    billing    = inwx_domain_contact.lennart.id
  }
}

# Still being transferred from Namecheap; import once the transfer completes.
# resource "inwx_domain" "essen_jetzt" {
#   name = "essen.jetzt"
#   nameservers = [
#     "ns1.antibuild.ing",
#     "ns2.antibuild.ing",
#     "ns3.antibuild.ing",
#   ]
#
#   period        = "1Y"
#   renewal_mode  = "AUTORENEW"
#   transfer_lock = true
#
#   contacts {
#     registrant = inwx_domain_contact.lennart.id
#     tech       = inwx_domain_contact.lennart.id
#   }
# }

resource "inwx_domain" "rudelb_link" {
  name = "rudelb.link"
  nameservers = [
    "ns1.antibuild.ing",
    "ns2.antibuild.ing",
    "ns3.antibuild.ing",
  ]

  period        = "1Y"
  renewal_mode  = "AUTORENEW"
  transfer_lock = true

  contacts {
    registrant = inwx_domain_contact.lennart.id
    tech       = inwx_domain_contact.lennart.id
  }
}

resource "inwx_domain" "wirs_ing" {
  name = "wirs.ing"
  nameservers = [
    "ns1.antibuild.ing",
    "ns2.antibuild.ing",
    "ns3.antibuild.ing",
  ]

  period        = "1Y"
  renewal_mode  = "AUTORENEW"
  transfer_lock = true

  contacts {
    registrant = inwx_domain_contact.lennart.id
    tech       = inwx_domain_contact.lennart.id
  }
}

# Still being transferred from Namecheap; import once the transfer completes.
# resource "inwx_domain" "zebre_us" {
#   name = "zebre.us"
#   nameservers = [
#     "ns1.antibuild.ing",
#     "ns2.antibuild.ing",
#     "ns3.antibuild.ing",
#   ]
#
#   period        = "1Y"
#   renewal_mode  = "AUTORENEW"
#   transfer_lock = true
#
#   contacts {
#     registrant = inwx_domain_contact.lennart.id
#     tech       = inwx_domain_contact.lennart.id
#   }
# }

# Glue records for the nameservers that live under antibuild.ing itself.
# The IPs must match kashenblade (ns1), blanderdash (ns2) and sempriaq (ns3)
# in machines.nix.
resource "inwx_glue_record" "ns1_antibuild_ing" {
  hostname = "ns1.antibuild.ing"
  ip       = ["167.235.154.30", "2a01:4f8:c0c:d91f::1"]
}

resource "inwx_glue_record" "ns2_antibuild_ing" {
  hostname = "ns2.antibuild.ing"
  ip       = ["49.13.8.171", "2a01:4f8:c013:29b1::1"]
}

resource "inwx_glue_record" "ns3_antibuild_ing" {
  hostname = "ns3.antibuild.ing"
  ip       = ["192.227.228.220"]
}

# The KSKs of the knot-signed zones; publishing them makes INWX submit the
# matching DS records to the registries. The keys never rotate (ksk-lifetime
# is 0 in the knot policy) and were fetched from the zones themselves:
#   dig +short DNSKEY <domain> @ns1.antibuild.ing | grep ^257
# The digests were verified against the DS records already at the registries.

resource "inwx_dnssec_key" "antibuild_ing" {
  domain     = "antibuild.ing"
  public_key = "7zyez0mNeD+Hty2+F0Qy7hFHD0rEGNvJrzU2UxhHqaQNXtihN7cfkh/TBg/ohvQ+OKDHaMXS+YvfFMPsVMkg5Q=="
  algorithm  = 13
}

# chaosdarmstadt.de: add its key here once knot serves and signs the zone
# and the DNSKEY is visible on ns1.

resource "inwx_dnssec_key" "darmfest_de" {
  domain     = "darmfest.de"
  public_key = "ve3Zm51n59BDT29RAp4QF9NOZMbRZqP4PG2oQV4DaKHZpnflhMRoi07wi5/jJHd54QKi/IgB4i6zaTCukY9HoQ=="
  algorithm  = 13
}

# Still being transferred from Namecheap; uncomment after the import.
# resource "inwx_dnssec_key" "essen_jetzt" {
#   domain     = "essen.jetzt"
#   public_key = "S+nCCDudgsf//kMBcsjL41n3XYHJjztWeyM/3uYB9UouCMTFY3+yC+HdKNhRaqbZOhbF2TmeqtrN8uG6OQCcig=="
#   algorithm  = 13
# }

resource "inwx_dnssec_key" "rudelb_link" {
  domain     = "rudelb.link"
  public_key = "ld7zWej7FMkpPfY/Q4F2q+qqlKex/4/ImlX/hNntDrwc2t2MpAfh/Sbrmt+ZsIqH8Hr4QxXy2Nu7Wrm62ni8Cg=="
  algorithm  = 13
}

resource "inwx_dnssec_key" "wirs_ing" {
  domain     = "wirs.ing"
  public_key = "dz9CO/0wyZrCs776ss+jOeSgth2Fpj65QM+ZodDtBhEk3DrbEWJ0nfRGpRJn1OmBfVcU51AruN6T047nPSRt6A=="
  algorithm  = 13
}

# Still being transferred from Namecheap; uncomment after the import.
# resource "inwx_dnssec_key" "zebre_us" {
#   domain     = "zebre.us"
#   public_key = "OLZUOnog7zegeUT6n+i+mUiNqouspbLcy+6ywAo+7+C1waNzHQ58mY5bRXXoWxe2JBJQe6Edh/y+dr2CWtO9lg=="
#   algorithm  = 13
# }

# The resources above used to be for_each loops; keep the existing state.
moved {
  from = inwx_domain.domains["antibuild.ing"]
  to   = inwx_domain.antibuild_ing
}

moved {
  from = inwx_domain.domains["chaosdarmstadt.de"]
  to   = inwx_domain.chaosdarmstadt_de
}

moved {
  from = inwx_domain.domains["darmfest.de"]
  to   = inwx_domain.darmfest_de
}

moved {
  from = inwx_domain.domains["rudelb.link"]
  to   = inwx_domain.rudelb_link
}

moved {
  from = inwx_domain.domains["wirs.ing"]
  to   = inwx_domain.wirs_ing
}

moved {
  from = inwx_glue_record.nameservers["ns1.antibuild.ing"]
  to   = inwx_glue_record.ns1_antibuild_ing
}

moved {
  from = inwx_glue_record.nameservers["ns2.antibuild.ing"]
  to   = inwx_glue_record.ns2_antibuild_ing
}

moved {
  from = inwx_glue_record.nameservers["ns3.antibuild.ing"]
  to   = inwx_glue_record.ns3_antibuild_ing
}

moved {
  from = inwx_dnssec_key.ksk["antibuild.ing"]
  to   = inwx_dnssec_key.antibuild_ing
}

moved {
  from = inwx_dnssec_key.ksk["darmfest.de"]
  to   = inwx_dnssec_key.darmfest_de
}

moved {
  from = inwx_dnssec_key.ksk["rudelb.link"]
  to   = inwx_dnssec_key.rudelb_link
}

moved {
  from = inwx_dnssec_key.ksk["wirs.ing"]
  to   = inwx_dnssec_key.wirs_ing
}
