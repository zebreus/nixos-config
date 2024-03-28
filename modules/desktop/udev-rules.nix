# Udev rules for various devices that I use or have used
{ lib, config, pkgs, ... }:
let
  tangUdev = pkgs.writeTextFile {
    name = "tang-udev";
    text = ''
      # Copy this file to /etc/udev/rules.d/

      ACTION!="add|change", GOTO="openfpgaloader_rules_end"

      # gpiochip subsystem
      SUBSYSTEM=="gpio", MODE="0666", GROUP="plugdev", TAG+="uaccess"

      SUBSYSTEM!="usb|tty|hidraw", GOTO="openfpgaloader_rules_end"

      # Original FT232/FT245 VID:PID
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", MODE="666", GROUP="plugdev", TAG+="uaccess"

      # Original FT2232 VID:PID
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="666", GROUP="plugdev", TAG+="uaccess"

      # Original FT4232 VID:PID
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6011", MODE="666", GROUP="plugdev", TAG+="uaccess"

      # Original FT232H VID:PID
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6014", MODE="666", GROUP="plugdev", TAG+="uaccess"

      # Original FT231X VID:PID
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6015", MODE="666", GROUP="plugdev", TAG+="uaccess"

      # anlogic cable
      ATTRS{idVendor}=="0547", ATTRS{idProduct}=="1002", MODE="666", GROUP="plugdev", TAG+="uaccess"

      # altera usb-blaster
      ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6001", MODE="666", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6002", MODE="666", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6003", MODE="666", GROUP="plugdev", TAG+="uaccess"

      # altera usb-blasterII - uninitialized
      ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6810", MODE="666", GROUP="plugdev", TAG+="uaccess"
      # altera usb-blasterII - initialized
      ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6010", MODE="666", GROUP="plugdev", TAG+="uaccess"

      # dirtyJTAG
      ATTRS{idVendor}=="1209", ATTRS{idProduct}=="c0ca", MODE="666", GROUP="plugdev", TAG+="uaccess"

      # Jlink
      ATTRS{idVendor}=="1366", ATTRS{idProduct}=="0105", MODE="666", GROUP="plugdev", TAG+="uaccess"

      # NXP LPC-Link2
      ATTRS{idVendor}=="1fc9", ATTRS{idProduct}=="0090", MODE="666", GROUP="plugdev", TAG+="uaccess"

      # NXP ARM mbed
      ATTRS{idVendor}=="0d28", ATTRS{idProduct}=="0204", MODE="666", GROUP="plugdev", TAG+="uaccess"

      # icebreaker bitsy
      ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="6146", MODE="666", GROUP="plugdev", TAG+="uaccess"

      # orbtrace-mini dfu
      ATTRS{idVendor}=="1209", ATTRS{idProduct}=="3442", MODE="6646", GROUP="plugdev", TAG+="uaccess"

      LABEL="openfpgaloader_rules_end"
    '';

    destination = "/lib/udev/rules.d/50-tang.rules";

  };

  wallyUdev = pkgs.writeTextFile {
    name = "test";
    text = ''
      # Rule for
      # Teensy rules for the Ergodox EZ
      ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", ENV{ID_MM_DEVICE_IGNORE}="1"
      ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789A]?", ENV{MTP_NO_PROBE}="1"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789ABCD]?", MODE:="0666"
      KERNEL=="ttyACM*", MODE:="0666"
        
      # STM32 rules for the Moonlander and Planck EZ
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", \
          MODE:="0666", \
          SYMLINK+="stm32_dfu"
            
      # Rules for live training
      # Rule for all ZSA keyboards
      SUBSYSTEM=="usb", ATTR{idVendor}=="3297", GROUP="wheel"
      # Rule for the Moonlander
      SUBSYSTEM=="usb", ATTR{idVendor}=="3297", ATTR{idProduct}=="1969", GROUP="wheel"
      # Rule for the Ergodox EZ
      SUBSYSTEM=="usb", ATTR{idVendor}=="feed", ATTR{idProduct}=="1307", GROUP="wheel"
      # Rule for the Planck EZ
      SUBSYSTEM=="usb", ATTR{idVendor}=="feed", ATTR{idProduct}=="6060", GROUP="wheel"
    '';

    destination = "/lib/udev/rules.d/50-wally.rules";
  };

  icestickUdev = pkgs.writeTextFile {
    name = "test";
    text = ''
      ACTION=="add", ATTR{idVendor}=="0403", ATTR{idProduct}=="6010", MODE:="666"
    '';

    destination = "/lib/udev/rules.d/50-icestick.rules";
  };

  mxMasterConfigurationUdev = pkgs.writeTextFile {
    name = "mxMasterConfiguration";
    text = ''
      ACTION=="bind", SUBSYSTEM=="hid", DRIVER=="logitech-hidpp-device", RUN:="${pkgs.bash}/bin/bash -c 'sleep 2 ; ${pkgs.libratbag}/bin/ratbagctl \"Logitech MX Master 3 for Mac\" dpi set 2000 ; ${pkgs.libratbag}/bin/ratbagctl \"Logitech MX Master 3 for Mac\" rate set 500 ; ${pkgs.libratbag}/bin/ratbagctl \"Logitech MX Master 3 for Mac\" button 5 action set button 6 ; ${pkgs.libratbag}/bin/ratbagctl \"MX Master 3 Mac\" dpi set 2000 ; ${pkgs.libratbag}/bin/ratbagctl \"MX Master 3 Mac\" rate set 500 ; ${pkgs.libratbag}/bin/ratbagctl \"MX Master 3 Mac\" button 5 action set button 6 ; true'"
    '';

    destination = "/lib/udev/rules.d/50-mx-master-configuration.rules";
  };

  logicAnalyzerUdev = pkgs.writeTextFile {
    name = "test";
    text = ''
      ACTION=="add", ATTR{idVendor}=="1d50", ATTR{idProduct}=="608c", MODE:="666"
    '';

    destination = "/lib/udev/rules.d/50-logicanalyzer.rules";
  };

  tbsUdev = pkgs.writeTextFile {
    name = "tbsUdev";
    text = ''
      # Rules for the TBS tango 2 (And probably all raw HID devices)
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0666", GROUP="plugdev"
      ATTRS{idVendor}=="04d8", ATTRS{idProduct}=="f94c", MODE="666", GROUP="plugdev", TAG+="uaccess"

      
    '';

    destination = "/lib/udev/rules.d/99-hidraw-permisson.rules";
  };

  ddcUdev = pkgs.writeTextFile {
    name = "ddcUdev";
    text = ''
      # Sample rules to grant RW access to /dev/i2c devices.

      # This sample file can be modified and copied to /etc/udev/rules.d.  If file 
      # /etc/udev/rules.d/60-ddcutil-i2c.rules exists, it overrides a file with the 
      # same name in /usr/lib/udev/rules.d, which is created by ddcutil installation.
      # This can be useful in cases where the usual rules do not work as needed, or
      # during development. 

      # The usual case, using TAG+="uaccess":  If a /dev/i2c device is associated
      # with a video adapter, grant the current user access to it.
      SUBSYSTEM=="i2c-dev", KERNEL=="i2c-[0-9]*", ATTRS{class}=="0x030000", TAG+="uaccess" 

      # Assigns i2c devices to group i2c, and gives that group RW access.
      # Individual users must then be assigned to group i2c.
      # On some distributions, installing package i2c-tools creates this rule. 
      # (For example, on Ubuntu, see 40-i2c-tools.rules.)
      # KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"

      # Gives everyone RW access to the /dev/i2c devices: 
      # KERNEL=="i2c-[0-9]*",  MODE="0666"
    '';

    destination = "/lib/udev/rules.d/50-ddc.rules";
  };
in
{
  config = lib.mkIf config.modules.desktop.enable {
    services.udev.packages = [
      wallyUdev
      tbsUdev
      icestickUdev
      logicAnalyzerUdev
      tangUdev
      mxMasterConfigurationUdev
      ddcUdev
      pkgs.headsetcontrol
      pkgs.gnome.gnome-settings-daemon
    ];
  };
}
