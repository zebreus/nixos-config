{ lib, config, ... }:
let
  publicKeys = import ../secrets/public-keys.nix;

  borgRepos = [
    { name = "lennart_erms"; size = "3T"; }
    { name = "lennart_prandtl"; size = "3T"; }
    { name = "matrix"; size = "1T"; }
    { name = "mail_zebre_us"; size = "1T"; }
    { name = "janek"; size = "2T"; }
    { name = "janek-proxmox"; size = "2T"; }
  ];

in
{
  options.modules.borg-repo = {
    enable = lib.mkEnableOption ''
      Host borg backup repositories.
    
      Currently only tested for kappril, that name is hardcoded in some places.
    '';
  };

  config = lib.mkIf config.modules.borg-repo.enable {
    services.borgbackup.repos =
      (builtins.listToAttrs (builtins.map
        (repo: lib.nameValuePair repo.name {
          quota = repo.size;
          path = "/storage/borg/${repo.name}";
          authorizedKeysAppendOnly = [
            publicKeys."${repo.name}_backup_append_only"
          ];
          authorizedKeys = [
            publicKeys."${repo.name}_backup_trusted"
          ];
        })
        borgRepos)) //
      {
        # I can put unmanaged extra repos here
      };
  };
}
