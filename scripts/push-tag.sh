#!/bin/bash

wfile=$(mktemp /tmp/builder.XXXXXXXXX)

. version.sh

echo "****************************************************"
echo [${UBOOT}:${TFA}:${OPTEE}:${TI_FIRMWARE}]
echo "****************************************************"

cp public/base.sh public/get_n_install.sh
sed -i -e 's:TAG:'${UBOOT}'-'${TFA}'-'${TI_FIRMWARE}':g' public/get_n_install.sh

echo "${UBOOT}-${TFA}-${TI_FIRMWARE} release" > ${wfile}

git commit -a -F ${wfile} -s

git tag -a ${UBOOT}-${TFA}-${TI_FIRMWARE} -m "${UBOOT}-${TFA}-${TI_FIRMWARE}"

git push origin main --tags
