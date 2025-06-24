#!/bin/bash

. version.sh

echo "****************************************************"
echo [${UBOOT}:${TRUSTED_FIRMWARE}:${OPTEE}:${TI_FIRMWARE}]
echo "****************************************************"

cp public/base.sh public/get_n_install.sh
sed -i -e 's:TAG:'${UBOOT}'-'${TI_FIRMWARE}':g' public/get_n_install.sh

git commit -a -m 'Release ${UBOOT}-${TI_FIRMWARE}' -s
git tag -a ${UBOOT}-${TI_FIRMWARE} -m "${UBOOT}-${TI_FIRMWARE}"

echo "git push origin main --tags"
