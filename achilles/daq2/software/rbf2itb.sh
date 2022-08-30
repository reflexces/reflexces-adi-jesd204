#!/bin/bash

# run this script after successful make build of ADI DAQ2 Achilles
# to convert the generated .rbf files to u-boot .itb files.

HDL_BUILD_DIR=$HOME/adi-jesd204b/hdl/projects/daq2/achilles
UBOOT_DIR=$HOME/adi-jesd204b/software/u-boot-socfpga

cp $HDL_BUILD_DIR/daq2_achilles.periph.rbf $UBOOT_DIR
cp $HDL_BUILD_DIR/daq2_achilles.core.rbf $UBOOT_DIR

cd $UBOOT_DIR

tools/mkimage -E -f daq2_fit_spl_fpga_periph_only.its fit_spl_fpga_periph_only.itb 
tools/mkimage -E -f daq2_fit_spl_fpga.its fit_spl_fpga.itb

# copy the ITB files back over to the ADI hdl build directory
# they get overwritten in the u-boot directory each time we run mkimage,
# so this creates a backup in the hdl project directory
cp $UBOOT_DIR/daq2_fit_spl_fpga_periph_only.itb $HDL_BUILD_DIR
cp $UBOOT_DIR/daq2_fit_spl_fpga.itb $HDL_BUILD_DIR
