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
git clone --branch twrp-12.1 --depth 1 https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp twrp

#kernel
echo ">clone kernel source"
git clone --branch lineage-21 --depth 1 https://github.com/LineageOS/android_kernel_sony_sm8350 kernel

#device
echo ">clone device source"
git clone --branch main --depth 1 https://github.com/sonybasement/twrp_android_sony_pdx215 device/sony/pdx215

cd $BASE_PATH

#build
echo ">build kernel"
# 20241001 remove WERROR
sed -i 's/CONFIG_CC_WERROR=y/# CONFIG_CC_WERROR=y/g' arch/arm64/configs/pdx215_defconfig
export PATH="$BASE_PATH/toolchain/bin:${PATH}"
MAKE_ARGS="CC=clang O=out ARCH=arm64 LLVM=1 LLVM_IAS=1"
make $MAKE_ARGS "pdx215_defconfig"
make $MAKE_ARGS -j"$(nproc --all)"
cd $BASE_PATH
cp kernel/out/arch/arm64/boot/Image AnyKernel3/

#create dtb
echo ">create dtb and dtbo.img"
cat $(find kernel/out/arch/arm64/boot/dts/vendor/oplus/lemonadev/ -type f -name "*.dtb" | sort) > AnyKernel3/dtb
python libufdt/utils/src/mkdtboimg.py create AnyKernel3/dtbo.img --page_size=4096 $(find kernel/out/arch/arm64/boot/dts/vendor/oplus/lemonadev/ -type f -name "*.dtbo" | sort)

#create AnyKernel3 zip
echo ">clean AnyKernel3"
rm -rf AnyKernel3/.git* AnyKernel3/README.md
echo "lineageOS-21 oneplus-sm8350 kernel with KernelSU" > AnyKernel3/README.md
sed -i 's/do.devicecheck=1/do.devicecheck=0/g' AnyKernel3/anykernel.sh
sed -i 's!BLOCK=/dev/block/platform/omap/omap_hsmmc.0/by-name/boot;!BLOCK=auto;!g' AnyKernel3/anykernel.sh
sed -i 's/IS_SLOT_DEVICE=0;/IS_SLOT_DEVICE=auto;/g' AnyKernel3/anykernel.sh
