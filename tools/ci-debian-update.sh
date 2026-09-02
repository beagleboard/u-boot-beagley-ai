#!/bin/bash -x

echo "Acquire::http::Proxy \"http://192.168.1.10:3142\";" > /etc/apt/apt.conf.d/00aptproxy
apt-get update
apt-get dist-upgrade -yq
apt-get install -yq ccache device-tree-compiler gcc-arm-linux-gnueabihf libgnutls28-dev python3-cryptography python3-dev python3-jsonschema python3-pycryptodome python3-pyelftools python3-setuptools python3-yaml swig uuid-dev yamllint
