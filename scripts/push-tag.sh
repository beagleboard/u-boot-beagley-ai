#!/bin/bash

wfile=$(mktemp /tmp/builder.XXXXXXXXX)

. version.sh

echo "****************************************************"
echo [${UBOOT}:${TRUSTED_FIRMWARE}:${OPTEE}:${TI_FIRMWARE}]
echo "****************************************************"

cp public/base.sh public/get_n_install.sh
sed -i -e 's:TAG:'${UBOOT}'-'${TI_FIRMWARE}':g' public/get_n_install.sh

echo "${UBOOT}-${TI_FIRMWARE} release" > ${wfile}

git commit -a -F ${wfile} -s

git tag -a -F ${UBOOT}-${TI_FIRMWARE} -m "${UBOOT}-${TI_FIRMWARE}"

git push origin main --tags
