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

  esp32Udev = pkgs.writeTextFile {
    # Obtained from https://github.com/espressif/openocd-esp32/blob/master/contrib/60-openocd.rules
    name = "esp32Udev";
    text = ''
      # SPDX-License-Identifier: GPL-2.0-or-later

      # Copy this file to /etc/udev/rules.d/
      # If rules fail to reload automatically, you can refresh udev rules
      # with the command "udevadm control --reload"

      ACTION!="add|change", GOTO="openocd_rules_end"

      SUBSYSTEM=="gpio", MODE="0660", GROUP="plugdev", TAG+="uaccess"

      SUBSYSTEM!="usb|tty|hidraw", GOTO="openocd_rules_end"

      # Please keep this list sorted by VID:PID

      # opendous and estick
      ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="204f", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Original FT232/FT245 VID:PID
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Original FT2232 VID:PID
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Original FT4232 VID:PID
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6011", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Original FT232H VID:PID
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6014", MODE="660", GROUP="plugdev", TAG+="uaccess"
      # Original FT231XQ VID:PID
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6015", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Original FT2233HP VID:PID
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6040", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Original FT4233HP VID:PID
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6041", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Original FT2232HP VID:PID
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6042", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Original FT4232HP VID:PID
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6043", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Original FT233HP VID:PID
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6044", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Original FT232HP VID:PID
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6045", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Original FT4232HA VID:PID
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6048", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # DISTORTEC JTAG-lock-pick Tiny 2
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="8220", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # TUMPA, TUMPA Lite
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="8a98", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="8a99", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Marvell OpenRD JTAGKey FT2232D B
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="9e90", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # XDS100v2
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="a6d0", MODE="660", GROUP="plugdev", TAG+="uaccess"
      # XDS100v3
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="a6d1", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # OOCDLink
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="baf8", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Kristech KT-Link
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="bbe2", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Xverve Signalyzer Tool (DT-USB-ST), Signalyzer LITE (DT-USB-SLITE)
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="bca0", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="bca1", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # TI/Luminary Stellaris Evaluation Board FTDI (several)
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="bcd9", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # TI/Luminary Stellaris In-Circuit Debug Interface FTDI (ICDI) Board
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="bcda", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # egnite Turtelizer 2
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="bdc8", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Section5 ICEbear
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="c140", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="c141", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Amontec JTAGkey and JTAGkey-tiny
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="cff8", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # ASIX Presto programmer
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="f1a0", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Nuvoton NuLink
      ATTRS{idVendor}=="0416", ATTRS{idProduct}=="511b", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="0416", ATTRS{idProduct}=="511c", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="0416", ATTRS{idProduct}=="511d", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="0416", ATTRS{idProduct}=="5200", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="0416", ATTRS{idProduct}=="5201", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # TI ICDI
      ATTRS{idVendor}=="0451", ATTRS{idProduct}=="c32a", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # STMicroelectronics ST-LINK V1
      ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3744", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # STMicroelectronics ST-LINK/V2
      ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3748", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # STMicroelectronics ST-LINK/V2.1
      ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374b", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3752", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # STMicroelectronics STLINK-V3
      ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374d", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374e", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374f", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3753", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3754", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3755", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3757", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Cypress SuperSpeed Explorer Kit
      ATTRS{idVendor}=="04b4", ATTRS{idProduct}=="0007", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Cypress KitProg in KitProg mode
      ATTRS{idVendor}=="04b4", ATTRS{idProduct}=="f139", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Cypress KitProg in CMSIS-DAP mode
      ATTRS{idVendor}=="04b4", ATTRS{idProduct}=="f138", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Infineon DAP miniWiggler v3
      ATTRS{idVendor}=="058b", ATTRS{idProduct}=="0043", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Hitex LPC1768-Stick
      ATTRS{idVendor}=="0640", ATTRS{idProduct}=="0026", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Hilscher NXHX Boards
      ATTRS{idVendor}=="0640", ATTRS{idProduct}=="0028", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Hitex STR9-comStick
      ATTRS{idVendor}=="0640", ATTRS{idProduct}=="002c", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Hitex STM32-PerformanceStick
      ATTRS{idVendor}=="0640", ATTRS{idProduct}=="002d", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Hitex Cortino
      ATTRS{idVendor}=="0640", ATTRS{idProduct}=="0032", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Altera USB Blaster
      ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6001", MODE="660", GROUP="plugdev", TAG+="uaccess"
      # Altera USB Blaster2
      ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6010", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6810", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Ashling Opella-LD
      ATTRS{idVendor}=="0B6B", ATTRS{idProduct}=="0040", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Amontec JTAGkey-HiSpeed
      ATTRS{idVendor}=="0fbb", ATTRS{idProduct}=="1000", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # SEGGER J-Link
      ATTRS{idVendor}=="1366", ATTRS{idProduct}=="0101", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="1366", ATTRS{idProduct}=="0102", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="1366", ATTRS{idProduct}=="0103", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="1366", ATTRS{idProduct}=="0104", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="1366", ATTRS{idProduct}=="0105", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="1366", ATTRS{idProduct}=="0107", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="1366", ATTRS{idProduct}=="0108", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1010", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1011", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1012", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1013", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1014", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1015", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1016", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1017", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1018", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1020", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1051", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1055", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1061", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Raisonance RLink
      ATTRS{idVendor}=="138e", ATTRS{idProduct}=="9000", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Debug Board for Neo1973
      ATTRS{idVendor}=="1457", ATTRS{idProduct}=="5118", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # OSBDM
      ATTRS{idVendor}=="15a2", ATTRS{idProduct}=="0042", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="15a2", ATTRS{idProduct}=="0058", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="15a2", ATTRS{idProduct}=="005e", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Olimex ARM-USB-OCD
      ATTRS{idVendor}=="15ba", ATTRS{idProduct}=="0003", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Olimex ARM-USB-OCD-TINY
      ATTRS{idVendor}=="15ba", ATTRS{idProduct}=="0004", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Olimex ARM-JTAG-EW
      ATTRS{idVendor}=="15ba", ATTRS{idProduct}=="001e", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Olimex ARM-USB-OCD-TINY-H
      ATTRS{idVendor}=="15ba", ATTRS{idProduct}=="002a", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Olimex ARM-USB-OCD-H
      ATTRS{idVendor}=="15ba", ATTRS{idProduct}=="002b", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # ixo-usb-jtag - Emulation of a Altera Bus Blaster I on a Cypress FX2 IC
      ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="06ad", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # USBprog with OpenOCD firmware
      ATTRS{idVendor}=="1781", ATTRS{idProduct}=="0c63", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # TI/Luminary Stellaris In-Circuit Debug Interface (ICDI) Board
      ATTRS{idVendor}=="1cbe", ATTRS{idProduct}=="00fd", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # TI XDS110 Debug Probe (Launchpads and Standalone)
      ATTRS{idVendor}=="0451", ATTRS{idProduct}=="bef3", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="0451", ATTRS{idProduct}=="bef4", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="1cbe", ATTRS{idProduct}=="02a5", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # TI Tiva-based ICDI and XDS110 probes in DFU mode
      ATTRS{idVendor}=="1cbe", ATTRS{idProduct}=="00ff", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # isodebug v1
      ATTRS{idVendor}=="22b7", ATTRS{idProduct}=="150d", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # PLS USB/JTAG Adapter for SPC5xxx
      ATTRS{idVendor}=="263d", ATTRS{idProduct}=="4001", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Numato Mimas A7 - Artix 7 FPGA Board
      ATTRS{idVendor}=="2a19", ATTRS{idProduct}=="1009", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Ambiq Micro EVK and Debug boards.
      ATTRS{idVendor}=="2aec", ATTRS{idProduct}=="6010", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="2aec", ATTRS{idProduct}=="6011", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="2aec", ATTRS{idProduct}=="1106", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Espressif USB JTAG/serial debug units
      ATTRS{idVendor}=="303a", ATTRS{idProduct}=="1001", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="303a", ATTRS{idProduct}=="1002", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # ANGIE USB-JTAG Adapter
      ATTRS{idVendor}=="584e", ATTRS{idProduct}=="414f", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="584e", ATTRS{idProduct}=="424e", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="584e", ATTRS{idProduct}=="4255", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="584e", ATTRS{idProduct}=="4355", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="584e", ATTRS{idProduct}=="4a55", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Marvell Sheevaplug
      ATTRS{idVendor}=="9e88", ATTRS{idProduct}=="9e8f", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # Keil Software, Inc. ULink
      ATTRS{idVendor}=="c251", ATTRS{idProduct}=="2710", MODE="660", GROUP="plugdev", TAG+="uaccess"
      ATTRS{idVendor}=="c251", ATTRS{idProduct}=="2750", MODE="660", GROUP="plugdev", TAG+="uaccess"

      # CMSIS-DAP compatible adapters
      ATTRS{product}=="*CMSIS-DAP*", MODE="660", GROUP="plugdev", TAG+="uaccess"

      LABEL="openocd_rules_end"
    '';

    destination = "/lib/udev/rules.d/10-esp32.rules";
  };
in
{
  config = lib.mkIf config.machines.${config.networking.hostName}.desktop.enable {
    services.udev.packages = [
      wallyUdev
      tbsUdev
      icestickUdev
      logicAnalyzerUdev
      tangUdev
      mxMasterConfigurationUdev
      ddcUdev
      esp32Udev
      pkgs.headsetcontrol
      pkgs.gnome-settings-daemon
      pkgs.rivalcfg
    ];
  };
}
