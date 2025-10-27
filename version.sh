#!/bin/bash

#https://github.com/TexasInstruments/ti-linux-firmware.git
TI_FIRMWARE="${TI_FIRMWARE:-11.01.17}"

#https://github.com/TrustedFirmware-A/trusted-firmware-a.git
TFA_GIT="${TFA_GIT:-https://github.com/TrustedFirmware-A/trusted-firmware-a.git}"
TFA="lts-v2.12.7"

#https://github.com/OP-TEE/optee_os.git
OPTEE="4.8.0"

#https://github.com/beagleboard/u-boot.git
UBOOT_GIT="${UBOOT_GIT:-https://github.com/beagleboard/u-boot.git}"
UBOOT="${UBOOT:-v2025.10-Beagle}"
