## REFLEX CES board support for ADI JESD204B Framework

This repository contains instructions, scripts, and other files for working with supported ADI JESD204B Data Converter FMC cards on REFLEX CES boards.  It is currently intended for REFELEX CES internal use only (development & debug).  No customer support will be provided at this time.

ADI boards and REFLEX CES carrier boards currently supported:

| ADI FMC board | REFLEX Carrier     |
| ------------- |:------------------:|
| DAQ2          | Achilles Turbo SOM |

It is assumed that the user is familiar with working with the Achilles SOM, including basic tasks such as:
- establishing a serial connection to the SOM using terminal emulation software such as PuTTY or minicom
- booting the SOM to the Linux prompt
- booting the SOM using TFTP (required to modify full eMMC or individual eMMC partitions)
- copying new files to eMMC partitions using **scp**
- working within Linux environment and using basic Linux commands

If necessary, refer to the [Achilles SOM rocketboards.org page](https://www.rocketboards.org/foswiki/Documentation/REFLEXCESAchillesArria10SoCSOM) for assistance.

There are numerous ADI Reference Designs available to support multiple ADI FMC evaluation boards.  The reference designs are supported on various vendors' development kits (referred to as "carriers") and are released in the official ADI **hdl** github repository.  Within the repository, the **hdl/projects** folder contains additional folders for each supported board, and a **common** folder with subfolders for each supported "carrier".  This **common** folder includes carrier-specific code that could be reused to support other ADI FMC boards in the future.  The repository also includes the **hdl/library** folder with libraries containing the common JESD204 IP blocks used by multiple FMC cards.  See the second link below for more details on the HDL repository structure.  The first link below contains a "Table of Contents" with additional links providing more information on  working with the reference designs.

-[ADI HDL Reference Designs List](https://wiki.analog.com/resources/fpga/docs/hdl)

-[ADI github repository information](https://wiki.analog.com/resources/fpga/docs/git)

The HDL repository contains branches that are tested with specific versions of FPGA vendor tools.  At the time this work was started to support the first test board (DAQ2) on Achilles, the latest stable branch was **hdl_2019_r2** and should be used with **Quartus Prime Pro v19.3**.  You should have this version installed before attempting to follow the HDL project build instructions below.  For more information, view the [ADI Release information page](https://wiki.analog.com/resources/fpga/docs/releases).

Additionally, if running the Quartus build from Linux (highly recommended), you should also add the following line to end of your **.bashrc** file found in your user home directory:
```
export PATH=$PATH:$HOME/intelFPGA_pro/19.3/quartus/bin
```
This assumes you accepted the default installation path.  Modify your installation path in the **.bashrc** file if necessary.

There are 2 main components required to support any given ADI board on a carrier:
1. FPGA HDL design
2. Software (U-Boot, Linux kernel, devicetree, drivers, root filesystem)

### Building the FPGA HDL Design 

Note: all HDL development work to support Achilles was done on a Linux host (Ubuntu 20.04). It is possible to work in Windows if necessary, but Quartus tool setup instructions are not provided here.  Further, other software build tasks can only be done in a Linux environment; therefore it is recommended to do all work in Linux.  The Achilles Turbo SOM was used for development.  Achilles Indus SOM may work but has not been tested.  Achilles Lite SOM is not possible due to top FMC connectors not being installed.

For any carrier board that is not officially supported and maintained by ADI (including Achilles), a supported ADI design should be used as a baseline example for manually porting the design to the new carrier.  The Intel Arria 10 SoC Dev Kit (referred to as "a10soc" in the project list) was used as the example for porting to Achilles.  Refer to the [Porting ADI's HDL reference designs](https://wiki.analog.com/resources/fpga/docs/hdl/porting_project_quick_start_guide) wiki page for additional details.

Patch files and scripts are provided in this repository to add the files required to support the Achilles SOM.  To build the Quartus project for the DAQ2 board on Achilles SOM as carrier, open a terminal window and run the commands **exactly** as shown in the steps below:

1. On your host PC, create a working directory and then change to that directory.  It is recommended to use the directory name below because later commands and scripts will expect to find this absolute path.
```
mkdir -p $HOME/adi-jesd204b
cd $HOME/adi-jesd204b
```

2. Download and run the script **adi-daq2-achilles-apply-patch-build.sh**.  The script will clone the ADI HDL projects github repository, apply the patches for Achilles support for DAQ2, and then give you the option to launch the Quartus build, or manually start it later:
```
wget https://raw.githubusercontent.com/reflexces/reflexces-adi-jesd204/master/achilles/daq2/hdl/adi-daq2-achilles-apply-patch-build.sh
chmod +x adi-daq2-achilles-apply-patch-build.sh
source adi-daq2-achilles-apply-patch-build.sh
```

After the Quartus project build finishes successfully (you will see green "OK"), then change back to the main working directory:
```
cd $HOME/adi-jesd204b
```

### Building the Software Components

Some of the software components from the latest Achilles release on the [Achilles Rocketboards page](https://www.rocketboards.org/foswiki/Documentation/REFLEXCESAchillesArria10SoCSOM) can be used here.  Refer to the **Updating the Achilles eMMC** and other software sections below.

#### U-Boot

The U-Boot version from the latest Achilles release on rocketboards.org be used for working with the ADI FMC boards.  There is no need to compile a specific ADI version.  Currently, the Achilles DAQ2 Quaruts project is configured to generate split RBF configuration files for "HPS loads FPGA" configuration.  This means that we do need to run the **mkimage** utility from U-Boot to convert the split RBF files to ITB files that will be used by U-Boot to configure the FPGA.  Unfortunately, we do have to build U-Boot in order to generate the **mkimage** tool, even though we don't need to use the generated U-Boot binaries.  Run these commands in the terminal window from the directory created previously.

Run script to download and build U-Boot first to generate **mkimage**:
```
mkdir software && cd software
wget https://raw.githubusercontent.com/reflexces/reflexces-adi-jesd204/master/achilles/daq2/software/build-uboot-for-mkimage.sh
chmod +x build-uboot-for-mkimage.sh && ./build-uboot-for-mkimage.sh
```

Now we can run the script to convert the RBF files to ITB files:
```
wget https://raw.githubusercontent.com/reflexces/reflexces-adi-jesd204/master/achilles/daq2/software/rbf2itb.sh
chmod +x rbf2itb.sh && ./rbf2itb.sh
```

After the script completes, you should see messages about the FIT image descriptions and the 2 generated ITB files in the **u-boot-socfpga** directory:
- fit_spl_fpga_periph_only.itb 
- fit_spl_fpga.itb

These are the generic filenames hardcoded in the U-Boot source code, so do not rename them.  We will use them in the **Updating the Achilles eMMC** step below.

#### Linux Kernel, Devicetree & Drivers

ADI provides a script for building the kernel for Intel SOCFPGA devices.  It will clone the ADI kernel repository and download and setup the required Linaro toolchain.

For full details, visit the ADI wiki page [Building the Intel SoC-FPGA kernel and devicetrees from source](https://wiki.analog.com/resources/tools-software/linux-build/generic/socfpga).

Additional [ADI Linux information resource page](https://wiki.analog.com/resources/fpga/peripherals/jesd204/tutorial/linux).

For "quick start" instructions, follow these steps below.  In the terminal window opened previously, you should be at the directory **~/adi-jesd204b/software**.  Run these commands at the prompt.

Download the ADI script:
```
wget https://raw.githubusercontent.com/analogdevicesinc/wiki-scripts/master/linux/build_socfpga_kernel_image.sh
chmod +x build_socfpga_kernel_image.sh
```

Before launching the script, we need to insert commands into the script to download and apply the Achilles DAQ2 devicetree patch before it starts the kernel build:
```
sed -i '/pushd "$LINUX_DIR"/a wget https://raw.githubusercontent.com/reflexces/reflexces-adi-jesd204/master/achilles/daq2/software/0001-add-achilles-daq2-devicetrees.patch' build_socfpga_kernel_image.sh
sed -i '/.patch/a git apply 0001-add-achilles-daq2-devicetrees.patch' build_socfpga_kernel_image.sh
```

Launch the kernel build script:
```
./build_socfpga_kernel_image.sh linux-adi socfpga_arria10_achilles_daq2.dtb
```

After the kernel build completes, we will use the generated zImage and .dtb file in the **Updating the Achilles eMMC** step below.

#### Root Filesystem

There are several options for root filesystem generation:
1. Use the Yocto Poky root filesystem from the [latest Achilles release on rocketboards.org](https://www.rocketboards.org/foswiki/Documentation/REFLEXCESAchillesArria10SoCSOM) (full eMMC WIC image).

The latest released Yocto Poky rootfs is the fastest and easiest solution since it involves programming the Achilles eMMC with the latest released full WIC image as explained on the Achilles rocketboards page.  We will also make use of other software components (such as U-Boot) from this full WIC image, so this is an ideal solution.  The Poky image has also been updated to include in the build the **libiio** utilities used by ADI.  This Poky rootfs includes files used to demonstrate partial reconfiguration with the default Achilles reference design, and the ADI Linux kernel is not configured to support this.  Booting with this rootfs and the ADI kernel and devicetree will result in a kernel panic during boot, with warning messages related to missing drivers.  We will remove those files in a later step.

2. Build the Yocto Poky root filesystem using the Achilles build script on rocketboards.org.

Building the Yocto Poky rootfs will take extra time, but here we have the option to prevent the installation of the Partial Reconfiguration files into the rootfs.  This is done by manually modifying the machine configuration files in the meta-achilles layer, changing the line **GHRD_TYPE = "pr"** to **GHRD_TYPE = "std"** in the file **conf/machine/achilles-turbo.conf**.

3. Use the pre-built [ADI Kuiper Linux](https://wiki.analog.com/resources/tools-software/linux-software/embedded_arm_images) root filesystem.

The pre-built ADI rootfs would be the ideal solution since it contains all of the ADI provided utilities and software.  However, all attempts to boot using this rootfs result in the system hanging shortly after systemd processes begin to load.  No solution has been found yet for this issue.

### Updating the Achilles eMMC

To update the eMMC flash on Achilles, follow instructions on the Achilles rocketboards.org page (PROGRAM EMMC button at the top of page).  You can use the eMMC programming script or perform the steps manually if preferred.  The Achilles SOM must be connected to the local network using the Ethernet port and a TFTP server must already be setup to being to update the eMMC.  The recommended order of operation is as follows:

1. Program the latest released Achilles Turbo WIC image to the eMMC on the Turbo SOM.
2. Connect to the SOM using PuTTY or Minicom and the boot to the Linux prompt.
3. Delete the **/lib/firware** directory to remove the example PR files
```
rm -R /lib/firmware
```
4. Mount the eMMC FAT partition (partition 1) by running the script available at the Achilles SOM home directory:
```
./mount_fat.sh
```
This will mount eMMC partition 1 to /media/emmcp1 on Achilles.

For the next steps, you can either use the eMMC programming script (instructions on rocketboards.org page), or just manually **scp** files to the eMMC FAT partition.

The **scp** command will overwrite existing files with same names on the SOM eMMC FAT parition 1.  You may wish to first rename the files on the SOM to more easily revert back to these files if necessary.  From the Achilles SOM Linux prompt (in PuTTY or Minicom):
```
cd /media/emmcp1
mv fit_spl_fpga_periph_only.itb fit_spl_fpga_periph_only.itb.DEFAULT
mv fit_spl_fpga.itb fit_spl_fpga.itb.DEFAULT
```

5. From the host PC console, copy the ITB files generated in the U-Boot section above to Achilles eMMC partition 1.  You can find the Achilles IP address with the **ifconfig** command run on the Achilles SOM terminal emulator program.
```
cd $HOME/adi-jesd204b/software/u-boot-socfpga
scp *.itb root@<achilles_ip_addr>:/media/emmcp1
```
6. Copy the Linux kernel **zImage** and **socfpga_arria10_achilles_daq2.dtb** to eMMC partition 1.  We will copy these to a dedicated ADI directory and also add a U-Boot menu using the **linuxext.conf** file to allow us to choose which kernel, devicetree, and rootfs to use for the boot process.
```
cd $HOME/adi-jesd204b/software
ssh root@<achilles_ip_addr> "mkdir -p /media/emmcp1/adi"
scp zImage root@<achilles_ip_addr>:/media/emmcp1/adi
scp socfpga_arria10_achilles_daq2.dtb root@<achilles_ip_addr>:/media/emmcp1/adi
wget https://raw.githubusercontent.com/reflexces/reflexces-adi-jesd204/master/achilles/daq2/software/extlinux.conf
scp extlinux.conf root@<achilles_ip_addr>:/media/emmcp1/extlinux
```

Next, enter the **poweroff** command at the Achilles SOM Linux prompt and then power cycle the board to force FPGA configuration using the updated ITB files.

### Launching the Demo with IIO Oscilloscope

NOTE: There is no need to install or run IIO Oscilloscope until the JESD links are debugged and running on Achilles.

IIO Oscilloscope is an ADI GUI application use for plotting captured data from various FMC evaluation boards.  It can run under Windows or Linux.  The Windows installation uses a self-extracting installer and is fast and easy to setup.  The Linux installation requires building the source code.

To install and run under Windows:
1. Download the installer file **adi-osc-setup.exe** from the [ADI IIO Oscilloscope github page](https://github.com/analogdevicesinc/iio-oscilloscope/releases/tag/v0.14-master).
2. Launch the installer.
3. Launch the application from the Windows Start menu.

To install and run under Linux, follow these [instructions](https://wiki.analog.com/resources/tools-software/linux-software/iio_oscilloscope#installation).

Details about launching the application, setup, and use can also be found at the instructions link above.

### Debugging Resources

After successfully updating the eMMC with WIC image and additional generated files as described in previous steps, we can boot the SOM with the new files which will load the ADI DAQ2 FPGA design and ADI kernel and devicetree.  Once you reach the Linux prompt, scroll back through the boot messages to observe the current errors.

Refer to ADI Engineer Zone support request [JESD204 link failures with DAQ2 on custom Arria 10 board](https://ez.analog.com/linux-software-drivers/f/q-a/560995/jesd204-link-failures-with-daq2-on-custom-arria-10-board) for problem history and suggested workaround to update the devicetree with an entry the allows the errors to be ignored.

###### DAQ2 AD9523 PLL Clock Settings
It may be necessary to change the transceiver data rate and other PLL clock rates.  Refer to this link below for information on how the clocks are configured from the devicetree.
[AD-FMCDAQ2-EBZ Clocking](https://wiki.analog.com/resources/eval/user-guides/ad-fmcdaq2-ebz/clocking)

###### iio_info
This utility is useful for reading data from IIO devices (DACs, ADCs, sensors, PLLs, etc) and is part of the Libiio package (currently included by default in the latest Achilles Yocto Poky console image).
[iio_info](https://wiki.analog.com/resources/tools-software/linux-software/libiio/iio_info)
```
iio_info
```
More info on the [Linux Industrial I/O Subsystem](https://wiki.analog.com/software/linux/docs/iio/iio).

###### JESD204B Status
[JESD204B Status Utility](https://wiki.analog.com/resources/tools-software/linux-software/jesd_status)
This utility is provided with the ADI Kuiper root filesystem (which has not been successfully booted on Achilles yet).
A version of Yocto Poky rootfs (honister) with this utility compiled is available upon request.
Otherwise, similar information can be obtained by running the following command at the Achilles Poky Linux prompt:
```
grep "" /sys/bus/platform/drivers/axi-jesd204*/*/status /sys/bus/platform/drivers/axi-jesd204*/*/lane* /sys/bus/platform/drivers/axi-jesd204*/*/encoder
```
