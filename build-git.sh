#!/bin/bash
# Step by Step Guide: How to quickly build a trimmed Linux kernel
# https://www.leemhuis.info/files/misc/How%20to%20quickly%20build%20a%20trimmed%20Linux%20kernel%20%E2%80%94%20The%20Linux%20Kernel%20documentation.html

# Requirements for Debian/Ubuntu
#sudo apt install -y git bc build-essential flex bison openssl libssl-dev libelf-dev dwarves
#sudo apt install -y binutils gcc make pahole perl-base
#sudo apt install -y curl jq wget

# [Install build requirements](https://www.leemhuis.info/files/misc/How%20to%20quickly%20build%20a%20trimmed%20Linux%20kernel%20%E2%80%94%20The%20Linux%20Kernel%20documentation.html#install-build-requirements)

# Requirements for Windows
# Windows Powershell CLI
# %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe

# Fail on errors.
set -e

mkdir -p linux
pushd linux
#rm -rf *linux-* v*

if [[ -z $1 ]]; then
	linux_json="$(curl -s https://api.github.com/repos/torvalds/linux/tags | jq -r '.[0]')"
	linux_version="$(echo $linux_json | jq -r '.name')"
	linux_url="https://github.com/torvalds/linux.git"
else
	linux_tag=$1
	linux_version=linux-$linux_tag
	linux_url="https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git"
fi

if [[ ! -d ./sources ]]; then
	mkdir -p ./sources ./build
	echo "Clonning kernel..."
	git clone --depth 1 -b master ${linux_url} ./sources
	echo ""
	cd sources/
else
	echo -n "Housekeeping..."
	rm -rf ./build
	echo ""
	mkdir ./build
	cd sources/
	echo "Feching kernel..."
	git fetch --shallow-since='2 weeks'
	git checkout --force --detach origin/master
fi

# ➜ du -hs sources/
# 1.8G    sources/
#
# ➜ du -hs torvalds-linux-53b3c64/
# 5.5G    torvalds-linux-53b3c64/

echo -n "Copy custom default config..."
cp -f ../../Microsoft/config-wsl ../build/.config
echo ""

_start=$SECONDS

make O=../build/ olddefconfig
make -j $(nproc --all) O=../build/

_elapsedseconds=$(( SECONDS - _start ))
TZ=UTC0 printf 'Kernel builded: %(%H:%M:%S)T\n' "$_elapsedseconds"
echo "Kernel build finished: $(date -u '+%H:%M:%S')"

powershell.exe /C 'Copy-Item -Force ..\build\arch\x86\boot\bzImage $env:USERPROFILE\bzImage-'$linux_version
powershell.exe /C 'Write-Output [wsl2]`nkernel=$env:USERPROFILE\bzImage-'$linux_version' | % {$_.replace("\","\\")} | Out-File $env:USERPROFILE\.wslconfig -encoding ASCII'

popd
