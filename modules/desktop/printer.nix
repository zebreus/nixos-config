# Setup support for printers and scanners
{ pkgs, ... }:
{


  # Enable printing on HP printers
  services.printing = {
    enable = true;
    #  drivers = [ pkgs.hplip ];
  };

  # Enable scanning
  hardware.sane.enable = true;

  environment.systemPackages = with pkgs;
    [

      sane-backends
      xsane

    ];

  users.users.lennart.extraGroups = [ "lp" "scanner" ];
}
