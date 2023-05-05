#!/bin/bash
# Step by Step Guide: How to quickly build a trimmed Linux kernel
# https://www.leemhuis.info/files/misc/How%20to%20quickly%20build%20a%20trimmed%20Linux%20kernel%20%E2%80%94%20The%20Linux%20Kernel%20documentation.html

# Requirements for Debian/Ubuntu
#sudo apt install -y git bc build-essential flex bison openssl libssl-dev libelf-dev dwarves
#sudo apt install -y binutils gcc make pahole perl-base

# [Install build requirements](https://www.leemhuis.info/files/misc/How%20to%20quickly%20build%20a%20trimmed%20Linux%20kernel%20%E2%80%94%20The%20Linux%20Kernel%20documentation.html#install-build-requirements)

# Requirements for Windows
# Windows Powershell CLI
# %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe

# Fail on errors.
set -e

mkdir -p linux
pushd linux

linux_url="https://github.com/torvalds/linux.git"

if [ "$1" == "kernel" ]; then
	linux_url="https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git"
fi

echo -n "Housekeeping..."
rm -rf ./build
echo ""

if [[ ! -d ./sources ]]; then
	mkdir -p ./sources ./build
	echo "Clonning kernel..."
	git clone --depth 1 -b master ${linux_url} ./sources
	cd sources/
else
	mkdir ./build
	cd sources/
	echo "Feching kernel..."
	git fetch --depth 1
	git checkout --force --detach origin/master
fi

# ➜ du -hs sources/
# 1.8G    sources/
#
# ➜ du -hs torvalds-linux-53b3c64/
# 5.5G    torvalds-linux-53b3c64/

linux_version=v$(make -s kernelversion)

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

# Install kernel modules (Optional)
sudo make modules_install install O=../build/
cat /lib/modules/6.3.0-oleksis-microsoft-standard-WSL2+/modules.builtin
