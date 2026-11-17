# nixpkgs' passt, updated to release 2026_10_02. Older releases replace pasta's
# --address and --gateway (see ./network.nix) with link-local ones when the host
# has no address yet, as at boot. In that case, even this one forwards IPv6
# connections to :: instead of the guest's --address, which the patch fixes.
# Drop this once nixpkgs has a release with both fixes. Not an overlay, as that
# would also rebuild libvirt.
{ passt, fetchurl }:
passt.overrideAttrs rec {
  version = "2026_10_02.cba3570";
  src = fetchurl {
    url = "https://passt.top/passt/snapshot/passt-${version}.tar.gz";
    hash = "sha256-e4GJKxBwUh7SF95nLNzkPXo3Q25vhQzQTytjkZrEhLY=";
  };
  patches = [ ./passt-ipv6-local.patch ];
}
