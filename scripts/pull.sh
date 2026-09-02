#!/bin/bash

. version.sh

git pull --no-edit https://github.com/beagleboard/${BUILD_REPO}.git main
git pull --no-edit https://gitlab.com/beagle-pkgs/${BUILD_REPO}.git main
