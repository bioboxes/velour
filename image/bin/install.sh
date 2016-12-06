#!/bin/bash

set -o errexit
set -o nounset
set -o xtrace

fetch(){
	mkdir -p /usr/local/$2
	TMP=$(mktemp)
	wget $1 --quiet --output-document ${TMP}
	tar xf ${TMP} --directory /usr/local/$2 --strip-components=1
	rm ${TMP}
}

NON_ESSENTIAL_BUILD="make g++ wget unzip ca-certificates xz-utils bzip2 g++-multilib patch"
ESSENTIAL_BUILD=""
RUNTIME="bc"

# Build dependencies
apt-get update --yes
apt-get install --yes --no-install-recommends ${NON_ESSENTIAL_BUILD} ${ESSENTIAL_BUILD}

fetch https://github.com/jjcook/velour/archive/${RELEASE}.tar.gz velour

cd /usr/local/velour
cat /usr/local//share/biobox.patch | patch -p1
make 'MAXKMERLENGTH=63'
ls velour_minikmer_ptables*.tar.bz2 | xargs -n 1 tar xjvf
ls | egrep -v 'velour|minikmer|.sh' | xargs rm -r
rm *.tar.bz2

# Clean up dependencies
apt-get autoremove --purge --yes ${NON_ESSENTIAL_BUILD}
apt-get clean

# Install required files
apt-get install --yes --no-install-recommends ${RUNTIME}
rm -rf /var/lib/apt/lists/*
