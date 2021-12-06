#!/bin/bash

# Requirements for Debian/Ubuntu
#sudo apt install -y git bc build-essential flex bison libssl-dev libelf-dev dwarves
#sudo apt install -y curl jq

# Requirements for openSUSE
#sudo zypper in -y -t pattern devel_basis
#sudo zypper in -y bc openssl openssl-devel dwarves rpm-build libelf-devel
#sudo zypper in -y curl jq

# Fail on errors.
set -e

mkdir -p linux
pushd linux

linux_json="$(curl -s https://api.github.com/repos/torvalds/linux/tags | jq -r '.[0]')"
linux_name="$(echo $linux_json | jq -r '.name')"

# echo $linux_name | sed 's/$/.tar.gz/' | sed 's#^#https://github.com/torvalds/linux/archive/refs/tags/#' | wget -c -i -
echo $linux_json | jq -r '.tarball_url' | wget -c -i -

echo -n "Untar $linux_name..."
tar -xf "$linux_name"
echo ""

cd "$(find -maxdepth 1 -type d -regex '\.\/.*linux-.*')"

echo -n "Copy custom default config..."
cp -f ../../Microsoft/config-wsl .config
echo ""

#SECONDS=0
_start=$SECONDS

make olddefconfig
#make silentoldconfig
make -j4

_elapsedseconds=$(( SECONDS - _start ))
TZ=UTC0 printf 'Kernel builded: %(%H:%M:%S)T\n' "$_elapsedseconds"
echo "Kernel build finished: $(date -u '+%H:%M:%S')"

powershell.exe /C 'Copy-Item -Force .\arch\x86\boot\bzImage $env:USERPROFILE\bzImage-'$linux_name
powershell.exe /C 'Write-Output [wsl2]`nkernel=$env:USERPROFILE\bzImage-'$linux_name' | % {$_.replace("\","\\")} | Out-File $env:USERPROFILE\.wslconfig -encoding ASCII'

popd

