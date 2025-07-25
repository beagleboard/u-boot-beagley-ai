#!/bin/bash

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

if [ -f ./tiboot3.bin ] ; then
	rm -rf ./tiboot3.bin || true
fi

if [ -f ./tispl.bin ] ; then
	rm -rf ./tispl.bin || true
fi

if [ -f ./u-boot.img ] ; then
	rm -rf ./u-boot.img || true
fi

wget https://beagle-pkgs.gitlab.io/u-boot-beagley-ai/tiboot3.bin
wget https://beagle-pkgs.gitlab.io/u-boot-beagley-ai/tispl.bin
wget https://beagle-pkgs.gitlab.io/u-boot-beagley-ai/u-boot.img

sync

if [ -d /boot/firmware/ ] ; then
	cp -v ./tiboot3.bin /boot/firmware/
	cp -v ./tispl.bin /boot/firmware/
	cp -v ./u-boot.img /boot/firmware/
	sync
fi

if [ -d /boot/efi/ ] ; then
	cp -v ./tiboot3.bin /boot/efi/
	cp -v ./tispl.bin /boot/efi/
	cp -v ./u-boot.img /boot/efi/
	sync
fi
#
