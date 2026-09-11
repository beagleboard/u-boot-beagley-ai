#!/bin/bash

BUILD_REPO="u-boot-beagley-ai"

#https://github.com/TexasInstruments/ti-linux-firmware.git
#https://github.com/TexasInstruments/ti-linux-firmware/compare/11.02.11...11.02.18
#https://forgejo.gfnd.rcn-ee.org:3000/TexasInstruments/ti-linux-firmware/compare/11.02.11...11.02.18
TI_FIRMWARE_GIT="${TI_FIRMWARE_GIT:-https://github.com/TexasInstruments/ti-linux-firmware.git}"
TI_FIRMWARE="${TI_FIRMWARE:-11.02.11}"

#https://github.com/TrustedFirmware-A/trusted-firmware-a.git
#https://github.com/TrustedFirmware-A/trusted-firmware-a/compare/lts-v2.14.5...lts-v2.14.6
#https://forgejo.gfnd.rcn-ee.org:3000/mirror/trusted-firmware-a/compare/lts-v2.14.5...lts-v2.14.6
TFA_GIT="${TFA_GIT:-https://review.trustedfirmware.org/TF-A/trusted-firmware-a.git}"
TFA="${TFA:-lts-v2.14.1}"

#https://github.com/OP-TEE/optee_os.git
#https://github.com/OP-TEE/optee_os/compare/4.9.0...4.10.0
#https://forgejo.gfnd.rcn-ee.org:3000/mirror/optee_os/compare/4.9.0...4.10.0
OPTEE_GIT="${OPTEE_GIT:-https://github.com/OP-TEE/optee_os.git}"
OPTEE="${OPTEE:-4.10.0}"

#https://github.com/beagleboard/u-boot.git
#https://github.com/beagleboard/u-boot/commits/v2026.04-Beagle/
#https://forgejo.gfnd.rcn-ee.org:3000/BeagleBoard.org/u-boot/compare/v2026.01-Beagle...v2026.04-Beagle
UBOOT_GIT="${UBOOT_GIT:-https://github.com/beagleboard/u-boot.git}"
UBOOT="${UBOOT:-v2026.01-Beagle}"
