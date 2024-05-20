## _module\.args

Additional arguments passed to each module in addition to ones
like ` lib `, ` config `,
and ` pkgs `, ` modulesPath `\.

This option is also available to all submodules\. Submodules do not
inherit args from their parent module, nor do they provide args to
their parent module or sibling submodules\. The sole exception to
this is the argument ` name ` which is provided by
parent modules to a submodule and contains the attribute name
the submodule is bound to, or a unique generated name if it is
not bound to an attribute\.

Some arguments are already passed by default, of which the
following *cannot* be changed with this option:

 - ` lib `: The nixpkgs library\.

 - ` config `: The results of all options after merging the values from all modules together\.

 - ` options `: The options declared in all modules\.

 - ` specialArgs `: The ` specialArgs ` argument passed to ` evalModules `\.

 - All attributes of ` specialArgs `
   
   Whereas option values can generally depend on other option values
   thanks to laziness, this does not apply to ` imports `, which
   must be computed statically before anything else\.
   
   For this reason, callers of the module system can provide ` specialArgs `
   which are available during import resolution\.
   
   For NixOS, ` specialArgs ` includes
   ` modulesPath `, which allows you to import
   extra modules from the nixpkgs package tree without having to
   somehow make the module aware of the location of the
   ` nixpkgs ` or NixOS directories\.
   
   ```
   { modulesPath, ... }: {
     imports = [
       (modulesPath + "/profiles/minimal.nix")
     ];
   }
   ```

For NixOS, the default value for this option includes at least this argument:

 - ` pkgs `: The nixpkgs package set according to
   the ` nixpkgs.pkgs ` option\.



*Type:*
lazy attribute set of raw value

*Declared by:*
 - [lib/modules\.nix](lib/modules.nix)



## allBackupHosts



All hosts that are backup hosts\. Collected from machines\.



*Type:*
list of (submodule) *(read only)*



*Default:*
` [ ] `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.address



The last byte of the antibuilding IPv4 address of the machine\.



*Type:*
integer between 1 and 255 (both inclusive)



*Example:*
` 6 `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.authoritativeDns\.enable



Whether this machine is a authoritative DNS server



*Type:*
boolean



*Default:*
` false `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.authoritativeDns\.name



Name of this DNS server\. Should be like ns1, ns2, ns3,



*Type:*
null or string



*Default:*
` null `



*Example:*
` "ns1" `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.authoritativeDns\.primary



Whether this machine is the primary authoritative DNS server\. This one is responsible for DNSSEC signing\. There should be only one primary authoritative DNS server\.



*Type:*
boolean



*Default:*
` false `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.backupHost\.enable



This machine is hosting backups\. The machine should provide at least 5TB of storage\.



*Type:*
null or boolean



*Default:*
` false `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.backupHost\.locationPrefix



The prefix to the borg repo\. This string suffixed with the repo name is the full path to the borg repo\.



*Type:*
null or string



*Default:*
` "ssh://borg@<name>//storage/borg/" `



*Example:*
` "ssh://borg@janek-backup//backups/lennart/" `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.backupHost\.storagePath



The prefix of the path to the backup repos\. This should be a path on a separate disk\.



*Type:*
null or string



*Default:*
` "/storage/borg" `



*Example:*
` "/backups/lennart" `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.extraBorgRepos



Extra borg repos used by this machine\.



*Type:*
list of (submodule)



*Default:*
` [ ] `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.extraBorgRepos\.\*\.name



The name of the backup repository\. This is used to identify the backup repository on the backup host\.

You need keys for every backup repository\. Use ` nix run .#gen-borg-keys <this_name> <machines> lennart ` to generate the keys\.



*Type:*
string

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.extraBorgRepos\.\*\.size



Limit the maximum size of the repo\.



*Type:*
string



*Default:*
` "2T" `



*Example:*
` "4T" `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.mailServer\.enable



Whether to enable Enable the mail server\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.mailServer\.baseDomain



Base domain for the mail server\. You need to setup the DNS records according to the
setup guide at https://nixos-mailserver\.readthedocs\.io/en/latest/setup-guide\.html
and https://nixos-mailserver\.readthedocs\.io/en/latest/autodiscovery\.html\. Also add
an additional SPF record for the mail subdomain\.



*Type:*
string

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.mailServer\.certEmail



Email address to use for Let’s Encrypt certificates\.



*Type:*
string

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.managed



Specify whether this machine is managed by this nixos-config



*Type:*
boolean



*Default:*
` false `



*Example:*
` false `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.matrixServer\.enable



Whether to enable Enable matrix server\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.matrixServer\.baseDomain



Base domain for the matrix server\. You need to setup the DNS records for this domain and for the matrix, element, and turn subdomains\.



*Type:*
string

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.matrixServer\.certEmail



Email address to use for Let’s Encrypt certificates\.



*Type:*
string

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.monitoring\.enable



Whether to enable Run grafana and the prometheus collector on this machine\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.name



Hostname of a machine on the network



*Type:*
string



*Example:*
` "bernd" `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.public



Whether this machine can be accessed by untrusted machines in the VPN\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.publicPorts



All other machines in the VPN are allowed to access these tcp ports on this machine\.



*Type:*
list of signed integer



*Default:*
` [ ] `



*Example:*
` true `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.sshPublicKey



The public SSH host key of this machine\. Implies that the machine can be accessed via SSH\.



*Type:*
null or (optionally newline-terminated) single-line string



*Default:*
` null `



*Example:*
` "xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=" `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.staticIp4



A static ipv4 address where this machine can be reached\.



*Type:*
null or string



*Default:*
` null `



*Example:*
` "10.192.122.3" `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.staticIp6



A static ipv6 address where this machine can be reached\.



*Type:*
null or string



*Default:*
` null `



*Example:*
` "1111:1111:1111:1111::1" `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.trusted



Whether this machine is allowed to access all other machines in the VPN\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.trustedPorts



This machine is allowed to access this tcp port on all other machines in the VPN\.



*Type:*
list of signed integer



*Default:*
` [ ] `



*Example:*
` true `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.vpnHub\.enable



Whether this machine is the hub of the VPN\.



*Type:*
boolean



*Default:*
` false `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.vpnHub\.staticIp4



A static ipv4 address where the hub can be reached\.



*Type:*
null or string *(read only)*



*Default:*
` null `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.vpnHub\.staticIp6



A static ipv6 address where the hub can be reached\.



*Type:*
null or string *(read only)*



*Default:*
` null `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.wireguardPublicKey



The base64 wireguard public key of the machine\.



*Type:*
(optionally newline-terminated) single-line string



*Example:*
` "xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=" `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBackupHosts\.\*\.workstation\.enable



This machine is a workstation\. It is used for daily work and should have lennart, a GUI, ssh keys and such\.

A home backup repo will be created for each workstation\.



*Type:*
null or boolean



*Default:*
` false `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBorgRepos



List of all borg repos that will get generated\. This is an internal option and should only be set implicitly\.

I am sure that there is a better way to solve this\.



*Type:*
list of (submodule)



*Default:*
` [ ] `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBorgRepos\.\*\.name



The name of the backup repository\. This is used to identify the backup repository on the backup host\.

You need keys for every backup repository\. Use ` nix run .#gen-borg-keys <this_name> <machines> lennart ` to generate the keys\.



*Type:*
string

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## allBorgRepos\.\*\.size



Limit the maximum size of the repo\.



*Type:*
string



*Default:*
` "2T" `



*Example:*
` "4T" `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## antibuilding\.customWireguardPrivateKeyFile



The wireguard private key for this machine\. Should only be set if the secrets of that machine are not managed in this repo



*Type:*
null or string



*Default:*
` null `

*Declared by:*
 - [modules/common/wireguard\.nix](modules/common/wireguard.nix)



## antibuilding\.customWireguardPskFile



Information about the machines in the network\. Should only be set if the secrets of that machine are not managed in this repo



*Type:*
null or string



*Default:*
` null `

*Declared by:*
 - [modules/common/wireguard\.nix](modules/common/wireguard.nix)



## antibuilding\.ipv6Prefix



The IPv6 prefix for the antibuilding\. There is not much reason to change this, I just added this option so I can reuse the prefix in other places\.



*Type:*
string



*Default:*
` "fd10:2030" `

*Declared by:*
 - [modules/common/wireguard\.nix](modules/common/wireguard.nix)



## machines



Information about the machines in the network



*Type:*
attribute set of (submodule)



*Default:*
` { } `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.address



The last byte of the antibuilding IPv4 address of the machine\.



*Type:*
integer between 1 and 255 (both inclusive)



*Example:*
` 6 `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.authoritativeDns\.enable



Whether this machine is a authoritative DNS server



*Type:*
boolean



*Default:*
` false `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.authoritativeDns\.name



Name of this DNS server\. Should be like ns1, ns2, ns3,



*Type:*
null or string



*Default:*
` null `



*Example:*
` "ns1" `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.authoritativeDns\.primary



Whether this machine is the primary authoritative DNS server\. This one is responsible for DNSSEC signing\. There should be only one primary authoritative DNS server\.



*Type:*
boolean



*Default:*
` false `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.backupHost\.enable



This machine is hosting backups\. The machine should provide at least 5TB of storage\.



*Type:*
null or boolean



*Default:*
` false `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.backupHost\.locationPrefix



The prefix to the borg repo\. This string suffixed with the repo name is the full path to the borg repo\.



*Type:*
null or string



*Default:*
` "ssh://borg@<name>//storage/borg/" `



*Example:*
` "ssh://borg@janek-backup//backups/lennart/" `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.backupHost\.storagePath



The prefix of the path to the backup repos\. This should be a path on a separate disk\.



*Type:*
null or string



*Default:*
` "/storage/borg" `



*Example:*
` "/backups/lennart" `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.extraBorgRepos



Extra borg repos used by this machine\.



*Type:*
list of (submodule)



*Default:*
` [ ] `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.extraBorgRepos\.\*\.name



The name of the backup repository\. This is used to identify the backup repository on the backup host\.

You need keys for every backup repository\. Use ` nix run .#gen-borg-keys <this_name> <machines> lennart ` to generate the keys\.



*Type:*
string

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.extraBorgRepos\.\*\.size



Limit the maximum size of the repo\.



*Type:*
string



*Default:*
` "2T" `



*Example:*
` "4T" `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.mailServer\.enable



Whether to enable Enable the mail server\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.mailServer\.baseDomain



Base domain for the mail server\. You need to setup the DNS records according to the
setup guide at https://nixos-mailserver\.readthedocs\.io/en/latest/setup-guide\.html
and https://nixos-mailserver\.readthedocs\.io/en/latest/autodiscovery\.html\. Also add
an additional SPF record for the mail subdomain\.



*Type:*
string

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.mailServer\.certEmail



Email address to use for Let’s Encrypt certificates\.



*Type:*
string

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.managed



Specify whether this machine is managed by this nixos-config



*Type:*
boolean



*Default:*
` false `



*Example:*
` false `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.matrixServer\.enable



Whether to enable Enable matrix server\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.matrixServer\.baseDomain



Base domain for the matrix server\. You need to setup the DNS records for this domain and for the matrix, element, and turn subdomains\.



*Type:*
string

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.matrixServer\.certEmail



Email address to use for Let’s Encrypt certificates\.



*Type:*
string

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.monitoring\.enable



Whether to enable Run grafana and the prometheus collector on this machine\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.name



Hostname of a machine on the network



*Type:*
string



*Example:*
` "bernd" `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.public



Whether this machine can be accessed by untrusted machines in the VPN\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.publicPorts



All other machines in the VPN are allowed to access these tcp ports on this machine\.



*Type:*
list of signed integer



*Default:*
` [ ] `



*Example:*
` true `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.sshPublicKey



The public SSH host key of this machine\. Implies that the machine can be accessed via SSH\.



*Type:*
null or (optionally newline-terminated) single-line string



*Default:*
` null `



*Example:*
` "xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=" `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.staticIp4



A static ipv4 address where this machine can be reached\.



*Type:*
null or string



*Default:*
` null `



*Example:*
` "10.192.122.3" `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.staticIp6



A static ipv6 address where this machine can be reached\.



*Type:*
null or string



*Default:*
` null `



*Example:*
` "1111:1111:1111:1111::1" `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.trusted



Whether this machine is allowed to access all other machines in the VPN\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.trustedPorts



This machine is allowed to access this tcp port on all other machines in the VPN\.



*Type:*
list of signed integer



*Default:*
` [ ] `



*Example:*
` true `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.vpnHub\.enable



Whether this machine is the hub of the VPN\.



*Type:*
boolean



*Default:*
` false `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.vpnHub\.staticIp4



A static ipv4 address where the hub can be reached\.



*Type:*
null or string *(read only)*



*Default:*
` null `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.vpnHub\.staticIp6



A static ipv6 address where the hub can be reached\.



*Type:*
null or string *(read only)*



*Default:*
` null `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.wireguardPublicKey



The base64 wireguard public key of the machine\.



*Type:*
(optionally newline-terminated) single-line string



*Example:*
` "xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=" `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## machines\.\<name>\.workstation\.enable



This machine is a workstation\. It is used for daily work and should have lennart, a GUI, ssh keys and such\.

A home backup repo will be created for each workstation\.



*Type:*
null or boolean



*Default:*
` false `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## modules\.auto-maintenance\.enable



Enable automatic maintenance tasks\.



*Type:*
boolean



*Default:*
` true `

*Declared by:*
 - [modules/auto-maintenance\.nix](modules/auto-maintenance.nix)



## modules\.boot\.type



How to configure the boot loader\. The default is “efi” which installs systemd-boot into ` /boot/efi `\.

“legacy” uses grub for BIOS systems\. “raspi” uses extlinux for Raspberry Pi\.



*Type:*
one of “efi”, “legacy”, “raspi”



*Default:*
` "efi" `

*Declared by:*
 - [modules/common/boot\.nix](modules/common/boot.nix)



## modules\.desktop\.enable



Enable GUI stuff for this machine



*Type:*
unspecified value



*Default:*
` false `

*Declared by:*
 - [modules/desktop](modules/desktop)



## modules\.workstation\.enable



This is a machine I use interactivly regularly (laptop, desktop, etc\.)



*Type:*
unspecified value



*Default:*
` false `

*Declared by:*
 - [modules/workstation](modules/workstation)



## services\.borgbackup\.jobs



Normal borg backup jobs\.



*Type:*
attribute set of (submodule)

*Declared by:*
 - [modules/helpers/borgMeteredConnectionOption\.nix](modules/helpers/borgMeteredConnectionOption.nix)



## services\.borgbackup\.jobs\.\<name>\.dontStartOnMeteredConnection



Whether the backup will start if the connection is metered\.



*Type:*
boolean



*Default:*
` false `

*Declared by:*
 - [modules/helpers/borgMeteredConnectionOption\.nix](modules/helpers/borgMeteredConnectionOption.nix)


