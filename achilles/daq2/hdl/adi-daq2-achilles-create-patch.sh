#!/bin/bash

# cd to your desired working directory before running this script (example: ~/adi)
# make sure the executable bit is set for this script before running

d=/home/dan/work/JESD204B/adi-patch-build-test-$(date -d "today" +"%m%d%Y")
mkdir -p "$d"
pushd $d > /dev/null
git clone https://github.com/analogdevicesinc/hdl.git
pushd hdl > /dev/null
git checkout hdl_2019_r2

cp -v /home/dan/work/JESD204B/ADI/hdl/0001-avl_dacfifo-Make-address-parametrizable.patch .

# copy files from known good build directory to new test directory
printf "Copying files...\n"
mkdir -p ./projects/common/achilles
cp -v /home/dan/work/JESD204B/ADI/hdl/projects/common/achilles/achilles_plddr4_assign.tcl ./projects/common/achilles
cp -v /home/dan/work/JESD204B/ADI/hdl/projects/common/achilles/achilles_plddr4_dacfifo_qsys.tcl ./projects/common/achilles
cp -v /home/dan/work/JESD204B/ADI/hdl/projects/common/achilles/achilles_system_assign.tcl ./projects/common/achilles
cp -v /home/dan/work/JESD204B/ADI/hdl/projects/common/achilles/achilles_system_qsys.tcl ./projects/common/achilles

cp -v /home/dan/work/JESD204B/ADI/hdl/projects/scripts/adi_project_intel.tcl ./projects/scripts

mkdir -p ./projects/daq2/achilles
cp -v /home/dan/work/JESD204B/ADI/hdl/projects/daq2/achilles/Makefile ./projects/daq2/achilles
cp -v /home/dan/work/JESD204B/ADI/hdl/projects/daq2/achilles/system_constr.sdc ./projects/daq2/achilles
cp -v /home/dan/work/JESD204B/ADI/hdl/projects/daq2/achilles/system_project.tcl ./projects/daq2/achilles
cp -v /home/dan/work/JESD204B/ADI/hdl/projects/daq2/achilles/system_qsys.tcl ./projects/daq2/achilles
cp -v /home/dan/work/JESD204B/ADI/hdl/projects/daq2/achilles/system_top.v ./projects/daq2/achilles
cp -v /home/dan/work/JESD204B/ADI/hdl/projects/daq2/achilles/quartus.ini ./projects/daq2/achilles

# create the patches
# keep "common" and "DAQ2" as separate patches to make future ADI project support easier
printf "Creating patch files...\n"
git add ./projects/common/achilles/achilles_plddr4_assign.tcl
git add ./projects/common/achilles/achilles_plddr4_dacfifo_qsys.tcl
git add ./projects/common/achilles/achilles_system_assign.tcl
git add ./projects/common/achilles/achilles_system_qsys.tcl
git add ./projects/scripts/adi_project_intel.tcl
git commit -m "add support for REFLEX CES Achilles SOM as carrier"
git format-patch -n HEAD^ -s

git add ./projects/daq2/achilles/Makefile
git add ./projects/daq2/achilles/system_constr.sdc
git add ./projects/daq2/achilles/system_project.tcl
git add ./projects/daq2/achilles/system_qsys.tcl
git add ./projects/daq2/achilles/system_top.v
git add ./projects/daq2/achilles/quartus.ini
git commit -m "add support for daq2 on achilles"
git format-patch -n HEAD^ -s

printf "Renaming patch files...\n"
mv 0001-add-support-for-REFLEX-CES-Achilles-SOM-as-carrier.patch 0002-add-support-for-REFLEX-CES-Achilles-SOM-as-carrier.patch
mv 0001-add-support-for-daq2-on-achilles.patch 0003-add-support-for-daq2-on-achilles.patch

printf "Creating gzip archive...\n"
tar cvzf adi-achilles-patches.tar.gz *.patch 

popd > /dev/null
popd > /dev/null

printf "Done.\n"
