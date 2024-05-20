# openVPN config for the pentest lab
# TODO: Remove once the lab is completed
{ lib, config, ... }:
{
  config = lib.mkIf config.machines.${config.networking.hostName}.workstation.enable {
    age.secrets = {
      "pentest_lab_ovpn.conf" = {
        file = ../../secrets/pentest_lab_ovpn.conf.age;
      };
    };
    services.openvpn.servers = {
      pentestLabVPN = { config = '' config ${config.age.secrets."pentest_lab_ovpn.conf".path} ''; };
    };
  };
}
