#!/bin/bash

. version.sh

echo "****************************************************"
echo [${UBOOT}:${TRUSTED_FIRMWARE}:${OPTEE}:${TI_FIRMWARE}]
echo "****************************************************"

git tag -a ${UBOOT}-${TI_FIRMWARE} -m "${UBOOT}-${TI_FIRMWARE}"
