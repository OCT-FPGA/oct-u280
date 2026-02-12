#!/usr/bin/env bash

install_xrt() {
    echo "Install XRT"
    if [[ "$OSVERSION" == "ubuntu-20.04" ]] || [[ "$OSVERSION" == "ubuntu-22.04" ]]; then
        echo "Ubuntu XRT install"
        echo "Installing XRT dependencies..."
        apt update
        echo "Installing XRT package..."
        apt install -y $XRT_BASE_PATH/$TOOLVERSION/$OSVERSION/$XRT_PACKAGE
    fi
    sudo bash -c "echo 'source /opt/xilinx/xrt/setup.sh' >> /etc/profile"
    sudo bash -c "echo 'source $VITIS_BASE_PATH/$TOOLVERSION/settings64.sh' >> /etc/profile"
}

install_u280_dev_platform(){
    echo "Install u280 dev platform"
    cp $U280_DEV_PLATFORM_PATH/$TOOLVERSION/*.deb /tmp
    apt install /tmp/xilinx-u280*.deb
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
    else
        echo "Unsupported OS: $OSVERSION"
        exit 1 
    fi
}

check_xrt() {
    if [[ "$OSVERSION" == "ubuntu-20.04" ]] || [[ "$OSVERSION" == "ubuntu-22.04" ]]; then
        XRT_INSTALL_INFO=`apt list --installed 2>/dev/null | grep "xrt" | grep "$XRT_VERSION"`
    else
        echo "Unsupported OS: $OSVERSION"
        exit 1 
    fi
}

install_xbflash() {
    cp -r $XBFLASH_BASE_PATH/${OSVERSION} /tmp
    echo "Installing xbflash."
    if [[ "$OSVERSION" == "ubuntu-20.04" ]] || [[ "$OSVERSION" == "ubuntu-22.04" ]]; then
        apt install /tmp/${OSVERSION}/*.deb
    else
        echo "Unsupported OS: $OSVERSION"
        exit 1 
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
            tar xzvf $SHELL_BASE_PATH/$TOOLVERSION/$OSVERSION/$SHELL_PACKAGE -C /tmp/
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
    cp $CONFIG_FPGA_PATH/$OSVERSION/* /usr/local/bin
}

install_libs() {
    echo "Installing libs."
    sudo $VITIS_BASE_PATH/$TOOLVERSION/scripts/installLibs.sh
}

disable_pcie_fatal_error() {
    echo "Disabling PCIe fatal error reporting for node: $NODE_ID"
    sudo /share/tools/u280/pcie_disable_fatal.sh $PCI_ADDR
}

XRT_BASE_PATH="/share/tools/u280/deployment/xrt"
SHELL_BASE_PATH="/share/tools/u280/deployment/shell"
XBFLASH_BASE_PATH="/share/tools/u280/xbflash"
VITIS_BASE_PATH="/share/Xilinx/Vitis"
U280_DEV_PLATFORM_PATH="/share/tools/u280/dev_platform"
CONFIG_FPGA_PATH="/share/tools/u280/post-boot"

OSVERSION=`grep '^ID=' /etc/os-release | awk -F= '{print $2}'`
OSVERSION=`echo $OSVERSION | tr -d '"'`
VERSION_ID=`grep '^VERSION_ID=' /etc/os-release | awk -F= '{print $2}'`
VERSION_ID=`echo $VERSION_ID | tr -d '"'`
OSVERSION="$OSVERSION-$VERSION_ID"
WORKFLOW=$1
TOOLVERSION=$2
REMOTEDESKTOP=$3
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

install_libs
# Disable PCIe fatal error reporting
disable_pcie_fatal_error 
install_config_fpga
install_u280_dev_platform

if [ "$WORKFLOW" = "Vitis" ] ; then
    check_shellpkg
    if [ $? == 0 ]; then
        echo "Shell is already installed."

    else
        echo "Shell is not installed. Installing shell..."
        install_shellpkg
        check_shellpkg
        if [ $? == 0 ]; then
            echo "Shell was successfully installed. Flashing..."
            flash_card
            /usr/local/bin/post-boot-fpga
            #echo "Cold rebooting..."
            #sudo -u geniuser perl /local/repository/cold-reboot.pl
        else
            echo "Error: Shell installation failed."
            exit 1
        fi
    fi
    if check_requested_shell ; then
        echo "FPGA shell verified."
    else
        echo "Error: FPGA shell couldn't be verified."
        exit 1
    fi
else
    echo "Custom flow selected."
    install_xbflash
fi 

if [ $REMOTEDESKTOP == "True" ] ; then
    echo "Installing remote desktop software"
    apt install -y ubuntu-gnome-desktop
    echo "Installed gnome desktop"
    systemctl set-default multi-user.target
    apt install -y tigervnc-standalone-server
    echo "Installed vnc server"
fi
