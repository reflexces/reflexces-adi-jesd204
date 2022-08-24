#!/bin/bash

# cd to your desired working directory before running this script (example: ~/adi)
# make sure the executable bit is set for this script before running
# source this script using "source adi-daq2-achilles.sh" or ". adi-daq2-achilles.sh" to be left at the correct directory to start the make process after this script exits
# after this scripts exits, type "make" at the terminal prompt from the /project/daq2/achilles directory, or uncomment the make line below before running this script

STABLE_BRANCH=hdl_2019_r2

printf "Cloning ADI HDL project repository...\n\n"
git clone https://github.com/analogdevicesinc/hdl.git
pushd hdl > /dev/null
git checkout $STABLE_BRANCH

printf "Downloading patches for Achilles DAQ2 support...\n\n"
wget https://raw.githubusercontent.com/reflexces/reflexces-adi-jesd204/master/achilles/daq2/hdl/0001-avl_dacfifo-Make-address-parametrizable.patch
wget https://raw.githubusercontent.com/reflexces/reflexces-adi-jesd204/master/achilles/daq2/hdl/0002-add-support-for-REFLEX-CES-Achilles-SOM-as-carrier.patch
wget https://raw.githubusercontent.com/reflexces/reflexces-adi-jesd204/master/achilles/daq2/hdl/0003-add-support-for-daq2-on-achilles.patch

printf "Applying patches...\n\n"
git apply --reject --whitespace=fix 0001-avl_dacfifo-Make-address-parametrizable.patch
git apply --reject --whitespace=fix 0002-add-support-for-REFLEX-CES-Achilles-SOM-as-carrier.patch
git apply --reject --whitespace=fix 0003-add-support-for-daq2-on-achilles.patch

while true
do
	read -r -p "Do you want to launch the build now? [yes/no] : " response
	case "$response" in
		[yY][eE][sS]|[yY]) 
			pushd projects/daq2/achilles > /dev/null
			make
			break
        ;;
		[nN][oO]|[nN]) 
			printf "\n\nTo start the build manually, change to directory \"hdl/projects/daq2/achilles\" and then run command \"make\"\n\n"
			break
		;;
		*)
			printf "\nInvalid entry.\n\n"
		;;
	esac
done
