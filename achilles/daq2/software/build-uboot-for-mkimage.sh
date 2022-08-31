#!/bin/bash

HDL_BUILD_DIR=$HOME/adi-jesd204b/hdl/projects/daq2/achilles
UBOOT_DIR=$HOME/adi-jesd204b/software/u-boot-socfpga

printf "\n\nDownloading Linaro tools...\n\n"
wget https://developer.arm.com/-/media/Files/downloads/gnu/11.2-2022.02/binrel/gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf.tar.xz

printf "\n\nExtracting Linaro tools...\n\n"
tar xf gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf.tar.xz 
rm gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf.tar.xz

printf "\n\nSetting environment variables...\n\n"
export ARCH=arm 
export CROSS_COMPILE=$PWD/gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf/bin/arm-none-linux-gnueabihf- 

printf "\n\nCloning U-Boot repository...\n\n"
git clone https://github.com/altera-opensource/u-boot-socfpga 
cd $UBOOT_DIR
git checkout -b achilles ee63370553cd01f7237174fe1971991271b7648b 

printf "\n\nStarting U-Boot build...\n\n"
wget https://raw.githubusercontent.com/reflexces/meta-achilles/kirkstone/recipes-bsp/u-boot/files/v2021.07/0001-add-achilles-support-for-u-boot-socfpga_v2021.07.patch 
git apply 0001-add-achilles-support-for-u-boot-socfpga_v2021.07.patch 
./arch/arm/mach-socfpga/qts-filter-a10.sh $HDL_BUILD_DIR/hps_isw_handoff/hps.xml arch/arm/dts/socfpga_arria10_achilles_handoff.h 
make socfpga_arria10_achilles_turbo_defconfig 
make -j 64  

printf "\n\nDone.  Please confirm there are no compile errors before proceeding.\n\n"
