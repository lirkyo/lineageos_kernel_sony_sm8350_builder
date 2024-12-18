#!/bin/sh

BASE_PATH=$(pwd)
export KBUILD_BUILD_HOST=github
export KBUILD_BUILD_USER=github
export ARCH=arm64
echo ">${BASE_PATH}"

# system
echo ">install tools"
sudo apt update -y 
sudo apt install -y elfutils libarchive-tools

#libufdt
echo ">clone libufdt"
git clone --branch android14-qpr2-release --depth 1 "https://android.googlesource.com/platform/system/libufdt.git" libufdt 

#AnyKernel3
echo ">clone AnyKernel3"
git clone --depth 1 https://github.com/osm0sis/AnyKernel3  AnyKernel3

# toolchain
echo ">download toolchain"
mkdir toolchain
cd toolchain
curl -LO "https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman"
chmod +x ./antman
./antman -S
./antman --patch=glibc
cd $BASE_PATH

#TWRP
echo ">clone twrp source"
git clone --branch android-12.1 --depth 1 https://github.com/TeamWin/android_bootable_recovery twrp

#kernel
echo ">clone kernel source"
git clone --branch lineage-21 --depth 1 https://github.com/LineageOS/android_kernel_sony_sm8350 kernel

#device
echo ">clone device source"
git clone --branch lineage-21 --depth 1 https://github.com/LineageOS/android_device_sony_pdx215 device/sony/pdx215
git clone --branch lineage-21 --depth 1 https://github.com/LineageOS/android_device_sony_sm8350-common device/sony/sm8350-common
git clone --branch lineage-21 --depth 1 https://github.com/LineageOS/android_hardware_sony hardware/sony


cd $BASE_PATH
. build/envsetup.sh
repopick 6526 6049 5743 5693
lunch twrp_pdx215-userdebug
mka bootimage
cp kernel/out/arch/arm64/boot/Image AnyKernel3/

#create AnyKernel3 zip
echo ">clean AnyKernel3"
rm -rf AnyKernel3/.git* AnyKernel3/README.md
echo "lineageOS-21 oneplus-sm8350 kernel with KernelSU" > AnyKernel3/README.md
sed -i 's/do.devicecheck=1/do.devicecheck=0/g' AnyKernel3/anykernel.sh
sed -i 's!BLOCK=/dev/block/platform/omap/omap_hsmmc.0/by-name/boot;!BLOCK=auto;!g' AnyKernel3/anykernel.sh
sed -i 's/IS_SLOT_DEVICE=0;/IS_SLOT_DEVICE=auto;/g' AnyKernel3/anykernel.sh
