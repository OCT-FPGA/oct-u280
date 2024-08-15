#!/usr/bin/env bash

install_xrt() {
    echo "Install XRT"
    if [[ "$OSVERSION" == "ubuntu-20.04" ]] || [[ "$OSVERSION" == "ubuntu-22.04" ]]; then
        echo "Ubuntu XRT install"
        echo "Installing XRT dependencies..."
        apt update
        echo "Installing XRT package..."
        echo "/proj/octfpga-PG0/tools/deployment/xrt/$TOOLVERSION/$OSVERSION/$XRT_PACKAGE"
        apt install -y /proj/octfpga-PG0/tools/deployment/xrt/$TOOLVERSION/$OSVERSION/$XRT_PACKAGE
    #elif [[ "$OSVERSION" == "centos-8" ]]; then
    #    echo "CentOS 8 XRT install"
    #    echo "Installing XRT dependencies..."
    #    yum config-manager --set-enabled powertools
    #    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    #    yum config-manager --set-enabled appstream
    #    echo "Installing XRT package..."
    #    sudo yum install -y /tmp/$XRT_PACKAGE
    fi
    sudo bash -c "echo 'source /opt/xilinx/xrt/setup.sh' >> /etc/profile"
    sudo bash -c "echo 'source /proj/octfpga-PG0/tools/Xilinx/Vitis/$VITISVERSION/settings64.sh' >> /etc/profile"
}

install_shellpkg() {

if [[ "$U280" == 0 ]]; then
    echo "[WARNING] No FPGA Board Detected."
    exit 1;
fi
     
for PF in U280; do
    if [[ "$(($PF))" != 0 ]]; then
        echo "You have $(($PF)) $PF card(s). "
        PLATFORM=`echo "alveo-$PF" | awk '{print tolower($0)}'`
        install_u280_shell
    fi
done
}

check_shellpkg() {
    if [[ "$OSVERSION" == "ubuntu-20.04" ]] || [[ "$OSVERSION" == "ubuntu-22.04" ]]; then
        PACKAGE_INSTALL_INFO=`apt list --installed 2>/dev/null | grep "$PACKAGE_NAME" | grep "$PACKAGE_VERSION"`
    elif [[ "$OSVERSION" == "centos-8" ]]; then
        PACKAGE_INSTALL_INFO=`yum list installed 2>/dev/null | grep "$PACKAGE_NAME" | grep "$PACKAGE_VERSION"`
    fi
}

check_xrt() {
    if [[ "$OSVERSION" == "ubuntu-20.04" ]] || [[ "$OSVERSION" == "ubuntu-22.04" ]]; then
        XRT_INSTALL_INFO=`apt list --installed 2>/dev/null | grep "xrt" | grep "$XRT_VERSION"`
    elif [[ "$OSVERSION" == "centos-8" ]]; then
        XRT_INSTALL_INFO=`yum list installed 2>/dev/null | grep "xrt" | grep "$XRT_VERSION"`
    fi
}

install_xbflash() {
    cp -r /proj/octfpga-PG0/tools/xbflash/${OSVERSION} /tmp
    echo "Installing xbflash."
    if [[ "$OSVERSION" == "ubuntu-18.04" ]] || [[ "$OSVERSION" == "ubuntu-20.04" ]]; then
        apt install /tmp/${OSVERSION}/*.deb
    elif [[ "$OSVERSION" == "centos-7" ]] || [[ "$OSVERSION" == "centos-8" ]]; then
        yum install /tmp/${OSVERSION}/*.rpm
    fi    
}

check_requested_shell() {
    SHELL_INSTALL_INFO=`/opt/xilinx/xrt/bin/xbmgmt examine | grep "$DSA"`
}

check_factory_shell() {
    SHELL_INSTALL_INFO=`/opt/xilinx/xrt/bin/xbmgmt examine | grep "$FACTORY_SHELL"`
}

install_u280_shell() {
    check_shellpkg
    if [[ $? != 0 ]]; then
        # echo "Download Shell package"
        # wget -cO - "https://www.xilinx.com/bin/public/openDownload?filename=$SHELL_PACKAGE" > /tmp/$SHELL_PACKAGE
        if [[ $SHELL_PACKAGE == *.tar.gz ]]; then
            echo "Untar the package. "
            tar xzvf /proj/octfpga-PG0/tools/deployment/shell/$TOOLVERSION/$OSVERSION/$SHELL_PACKAGE -C /tmp/
            rm /tmp/$SHELL_PACKAGE
        fi
        echo "Install Shell"
        if [[ "$OSVERSION" == "ubuntu-20.04" ]] || [[ "$OSVERSION" == "ubuntu-22.04" ]]; then
            echo "Install Ubuntu shell package"
            apt-get install -y /tmp/xilinx*
        elif [[ "$OSVERSION" == "centos-8" ]]; then
            echo "Install CentOS shell package"
            yum install -y /tmp/xilinx*
        fi
        rm /tmp/xilinx*
    else
        echo "The package is already installed. "
    fi
}

flash_card() {
    echo "Flash Card(s). "
    /opt/xilinx/xrt/bin/xbmgmt program --base --device $PCI_ADDR
}

detect_cards() {
    lspci > /dev/null
    if [ $? != 0 ] ; then
        if [[ "$OSVERSION" == "ubuntu-20.04" ]] || [[ "$OSVERSION" == "ubuntu-22.04" ]]; then
            apt-get install -y pciutils
        elif [[ "$OSVERSION" == "centos-7" ]] || [[ "$OSVERSION" == "centos-8" ]]; then
            yum install -y pciutils
        fi
    fi
    if [[ "$OSVERSION" == "ubuntu-20.04" ]] || [[ "$OSVERSION" == "ubuntu-22.04" ]]; then
        PCI_ADDR=$(lspci -d 10ee: | awk '{print $1}' | head -n 1)
        if [ -n "$PCI_ADDR" ]; then
            U280=$((U280 + 1))
        else
            echo "Error: No card detected."
            exit 1
        fi
    fi
}

install_config_fpga() {
    echo "Installing config-fpga."
    cp /proj/octfpga-PG0/tools/config-fpga /usr/local/bin
}


disable_pcie_fatal_error() {

    echo "Disabling PCIe fatal error reporting for node: $NODE_ID"
    
    #local group1=("pc151" "pc153" "pc154" "pc155" "pc156" "pc157" "pc158" "pc159" "pc160" "pc161" "pc162" "pc163" "pc164" "pc165" "pc166" "pc167")
    #local group2=("pc168" "pc169" "pc170" "pc171" "pc172" "pc173" "pc174" "pc175")

    # Check which group the node id belongs to and run the corresponding command
    #if [[ " ${group1[@]} " =~ " $NODE_ID " ]]; then
    sudo /proj/octfpga-PG0/tools/pcie_disable_fatal.sh $PCI_ADDR
    #elif [[ " ${group2[@]} " =~ " $NODE_ID " ]]; then
    #    sudo /proj/octfpga-PG0/tools/pcie_disable_fatal.sh 37:00.0
    #else
    #    echo "Unknown node: $NODE_ID. No action taken."
    #fi
}

OSVERSION=`grep '^ID=' /etc/os-release | awk -F= '{print $2}'`
OSVERSION=`echo $OSVERSION | tr -d '"'`
VERSION_ID=`grep '^VERSION_ID=' /etc/os-release | awk -F= '{print $2}'`
VERSION_ID=`echo $VERSION_ID | tr -d '"'`
OSVERSION="$OSVERSION-$VERSION_ID"
WORKFLOW=$1
TOOLVERSION=$2
VITISVERSION="2023.1"
SCRIPT_PATH=/local/repository
COMB="${TOOLVERSION}_${OSVERSION}"
XRT_PACKAGE=`grep ^$COMB: $SCRIPT_PATH/spec.txt | awk -F':' '{print $2}' | awk -F';' '{print $1}' | awk -F= '{print $2}'`
SHELL_PACKAGE=`grep ^$COMB: $SCRIPT_PATH/spec.txt | awk -F':' '{print $2}' | awk -F';' '{print $2}' | awk -F= '{print $2}'`
DSA=`grep ^$COMB: $SCRIPT_PATH/spec.txt | awk -F':' '{print $2}' | awk -F';' '{print $3}' | awk -F= '{print $2}'`
PACKAGE_NAME=`grep ^$COMB: $SCRIPT_PATH/spec.txt | awk -F':' '{print $2}' | awk -F';' '{print $5}' | awk -F= '{print $2}'`
PACKAGE_VERSION=`grep ^$COMB: $SCRIPT_PATH/spec.txt | awk -F':' '{print $2}' | awk -F';' '{print $6}' | awk -F= '{print $2}'`
XRT_VERSION=`grep ^$COMB: $SCRIPT_PATH/spec.txt | awk -F':' '{print $2}' | awk -F';' '{print $7}' | awk -F= '{print $2}'`
FACTORY_SHELL="xilinx_u280_GOLDEN_8"
NODE_ID=$(hostname | cut -d'.' -f1)
#PCI_ADDR=$(lspci -d 10ee: | awk '{print $1}' | head -n 1)

detect_cards
check_xrt
if [ $? == 0 ]; then
    echo "XRT is already installed."
else
    echo "XRT is not installed. Attempting to install XRT..."
    install_xrt

    check_xrt
    if [ $? == 0 ]; then
        echo "XRT was successfully installed."
    else
        echo "Error: XRT installation failed."
        exit 1
    fi
fi

if [ "$WORKFLOW" = "Vitis" ] ; then
    check_shellpkg
    if [ $? == 0 ]; then
        echo "Shell is already installed."
        if check_requested_shell ; then
            echo "FPGA shell verified."
        else
            echo "Error: FPGA shell couldn't be verified."
            exit 1
        fi
    else
        echo "Shell is not installed. Installing shell..."
        install_shellpkg
        check_shellpkg
        if [ $? == 0 ]; then
            echo "Shell was successfully installed. Flashing..."
            flash_card
            echo "Cold rebooting..."
            sudo -u geniuser perl /local/repository/cold-reboot.pl
        else
            echo "Error: Shell installation failed."
            exit 1
        fi
    fi
    
else
    echo "Custom flow selected."
    install_xbflash
    install_config_fpga
fi    
# Disable PCIe fatal error reporting
disable_pcie_fatal_error 
