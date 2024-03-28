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
` [ ] `

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



## machines\.\<name>\.wireguardPublicKey



The base64 wireguard public key of the machine\.



*Type:*
(optionally newline-terminated) single-line string



*Example:*
` "xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=" `

*Declared by:*
 - [modules/helpers/machines\.nix](modules/helpers/machines.nix)



## modules\.authoritative_dns\.enable



Whether to enable Enable the authoritative DNS server on port 53\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [modules/authoritative-dns\.nix](modules/authoritative-dns.nix)



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



## modules\.borg-repo\.enable



Whether to enable Host borg backup repositories\.

Currently only tested for kappril, that name is hardcoded in some places\.
\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [modules/borg-repo\.nix](modules/borg-repo.nix)



## modules\.desktop\.enable



Enable GUI stuff for this machine



*Type:*
unspecified value



*Default:*
` false `

*Declared by:*
 - [modules/desktop](modules/desktop)



## modules\.mail\.enable



Whether to enable Enable the mail server\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [modules/mail\.nix](modules/mail.nix)



## modules\.mail\.baseDomain



Base domain for the mail server\. You need to setup the DNS records according to the
setup guide at https://nixos-mailserver\.readthedocs\.io/en/latest/setup-guide\.html
and https://nixos-mailserver\.readthedocs\.io/en/latest/autodiscovery\.html\. Also add
an additional SPF record for the mail subdomain\.



*Type:*
string

*Declared by:*
 - [modules/mail\.nix](modules/mail.nix)



## modules\.mail\.certEmail



Email address to use for Let’s Encrypt certificates\.



*Type:*
string

*Declared by:*
 - [modules/mail\.nix](modules/mail.nix)



## modules\.matrix\.enable



Whether to enable Enable matrix server\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [modules/matrix\.nix](modules/matrix.nix)



## modules\.matrix\.baseDomain



Base domain for the matrix server\. You need to setup the DNS records for this domain and for the matrix, element, and turn subdomains\.



*Type:*
string

*Declared by:*
 - [modules/matrix\.nix](modules/matrix.nix)



## modules\.matrix\.certEmail



Email address to use for Let’s Encrypt certificates\.



*Type:*
string

*Declared by:*
 - [modules/matrix\.nix](modules/matrix.nix)



## modules\.workstation\.enable



This is a machine I use interactivly regularly (laptop, desktop, etc\.)



*Type:*
unspecified value



*Default:*
` false `

*Declared by:*
 - [modules/workstation](modules/workstation)



## services\.borgbackup\.jobs



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


