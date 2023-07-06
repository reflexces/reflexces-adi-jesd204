#!/bin/bash

WORK_DIR=$HOME/adi-jesd204b
HDL_BUILD_DIR=$HOME/adi-jesd204b/hdl/projects/daq2/achilles
UBOOT_DIR=$HOME/adi-jesd204b/software/u-boot-socfpga
LINARO_DIR=gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf
LINARO_ARCHIVE=$LINARO_DIR.tar.xz

if [[ "$PWD" != "$WORK_DIR/software" ]]; then
    printf "\n\nYou are not working from the expected directory $WORK_DIR.\n"
    printf "This and other scripts require this directory.  Please refer to the\n"
    printf "README.md file on the github page for instructions.\n\n"
    exit 1
fi

if [ ! -d ../$HDL_BUILD_DIR ]; then
    printf "\n\nCould not find the expected HDL build directory $HDL_BUILD_DIR.\n"
    printf "This script requires files from the HDL build to complete successfully.\n"
    printf "Please refer to the README.md file on the github page for instructions.\n\n"
    exit 1
fi

if [ ! -d ./$LINARO_DIR ]; then
    printf "\n\nDownloading Linaro tools...\n\n"
    wget https://developer.arm.com/-/media/Files/downloads/gnu/11.2-2022.02/binrel/gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf.tar.xz

    printf "\n\nExtracting Linaro tools...\n\n"
    tar xf gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf.tar.xz 
    rm gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf.tar.xz
else
    printf "\n\nLinaro tools already setup.\n\n"
fi


printf "\n\nSetting environment variables...\n\n"
export ARCH=arm 
export CROSS_COMPILE=$PWD/gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf/bin/arm-none-linux-gnueabihf- 

printf "\n\nCloning U-Boot repository...\n\n"
git clone https://github.com/altera-opensource/u-boot-socfpga 
cd $UBOOT_DIR
git checkout -b achilles ee63370553cd01f7237174fe1971991271b7648b 

printf "\n\nStarting U-Boot build...\n\n"
wget https://raw.githubusercontent.com/reflexces/meta-achilles/kirkstone/recipes-bsp/u-boot/files/v2021.07/0001-Add-Achilles-V2-support-for-u-boot-socfpga.patch 
git apply 0001-Add-Achilles-V2-support-for-u-boot-socfpga.patch 
./arch/arm/mach-socfpga/qts-filter-a10.sh $HDL_BUILD_DIR/hps_isw_handoff/hps.xml arch/arm/dts/socfpga_arria10_achilles_handoff.h 
make socfpga_arria10_achilles_v2_turbo_defconfig 
make -j 64  

printf "\n\nDone.  Please confirm there are no compile errors above before proceeding.\n\n"
