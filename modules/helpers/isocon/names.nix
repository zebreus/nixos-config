# Names and IDs shared by the files of this module.
{ lib }:
rec {
  unit = name: "isocon-${name}";
  networkUnit = name: "${unit name}-network";
  # Holds both units. Dashes in slice names mean nesting, so the name's are
  # escaped: isocon-foo-bar must not end up inside isocon-foo.
  slice = name: "isocon-${lib.replaceStrings [ "-" ] [ "\\x2d" ] name}";
  # The container's host user. Its UID and GID are uidBase.
  user = name: "isocon-${name}";
  runtimeDir = name: "/run/isocon/${name}";
  # The network unit's runtime directory (relative to /run), with a symlink to
  # the process that holds the container's namespaces: ${holder name}/ns/user
  # and ${holder name}/ns/net.
  networkDir = name: "isocon/${name}-network";
  holder = name: "/run/${networkDir name}/holder";

  # The host's UIDs and GIDs uidBase … uidBase + 65535 are the container's
  # 0 … 65535. From a hash of the name, because files in the container's /var
  # are owned by them and must keep their owners. In 64K steps within systemd's
  # range for containers (0x80000 … 0x6FFFFFFF); ./hardening.nix asserts that
  # they don't collide.
  uidBase = name: 524288 + 65536 * lib.mod (lib.fromHexString (builtins.substring 0 7 (builtins.hashString "sha256" name))) 28664;

  # The guest's machine ID. Stable, as it names the directory of its persisted
  # journal, /var/log/journal/${machineId name}.
  machineId = name: builtins.substring 0 32 (builtins.hashString "sha256" name);

  # The systemd.services entries of the containers' units and network units.
  units = unitsNamed unit;
  networkUnits = unitsNamed networkUnit;
  unitsNamed = unitName: cfg: f: lib.mapAttrs' (name: container: lib.nameValuePair (unitName name) (f name container)) cfg;
}
