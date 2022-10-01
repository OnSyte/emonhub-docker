#!/bin/bash
# -------------------------------------------------------------
# emonHub install and update script
# -------------------------------------------------------------
# Assumes emonhub repository installed via git:
# git clone https://github.com/openenergymonitor/emonhub.git

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
usrdir=${DIR/\/emonhub/}

openenergymonitor_dir=$1
if [ ! -f $openenergymonitor_dir/EmonScripts/update/load_config.sh ]; then
    emonSD_pi_env=""
else 
    cd $openenergymonitor_dir/EmonScripts/install
    source load_config.sh
fi

if [ "$emonSD_pi_env" = "" ]; then
    read -sp 'Apply raspberrypi serial configuration? 1=yes, 0=no: ' emonSD_pi_env
    echo
    echo "You entered $emonSD_pi_env"
    echo
    # Avoid running apt update if install script is being called from the EmonScripts update script
    sudo apt update
fi

sudo apt-get install -y python3-serial python3-configobj python3-pip python3-pymodbus bluetooth libbluetooth-dev
sudo pip3 install paho-mqtt requests pybluez py-sds011 sdm_modbus minimalmodbus

if [ "$emonSD_pi_env" = "1" ]; then
    # Only install the GPIO library if on a Pi. Used by Pulse interfacer
    pip3 install RPi.GPIO
    # Need to add the emonhub user to the GPIO group
    sudo adduser emonhub gpio

    # RaspberryPi Serial configuration
    # disable Pi3 Bluetooth and restore UART0/ttyAMA0 over GPIOs 14 & 15;
    # Review should this be: dtoverlay=miniuart-bt?
    sudo sed -i -n '/dtoverlay=disable-bt/!p;$a dtoverlay=disable-bt' /boot/config.txt

    # We also need to stop the Bluetooth modem trying to use UART
    sudo systemctl disable hciuart

    # Remove console from /boot/cmdline.txt
    sudo sed -i "s/console=serial0,115200 //" /boot/cmdline.txt

    # stop and disable serial service??
    sudo systemctl stop serial-getty@ttyAMA0.service
    sudo systemctl disable serial-getty@ttyAMA0.service
    sudo systemctl mask serial-getty@ttyAMA0.service
fi

cd $usrdir
if [ ! -d $usrdir/data ]; then
    mkdir data
fi

sudo useradd -M -r -G dialout,tty -c "emonHub user" emonhub

# ---------------------------------------------------------
# EmonHub config file
# ---------------------------------------------------------
if [ ! -d /etc/emonhub ]; then
    sudo mkdir /etc/emonhub
fi

if [ ! -f /etc/emonhub/emonhub.conf ]; then
    sudo cp $usrdir/emonhub/conf/emonpi.default.emonhub.conf /etc/emonhub/emonhub.conf
    # requires write permission for configuration from emoncms:config module
    sudo chmod 666 /etc/emonhub/emonhub.conf

    # Temporary: replace with update to default settings file
    sed -i "s/loglevel = DEBUG/loglevel = WARNING/" /etc/emonhub/emonhub.conf
fi

# ---------------------------------------------------------
# Symlink emonhub source to /usr/share/emonhub
# ---------------------------------------------------------
sudo ln -sf $usrdir/emonhub/src /usr/local/bin/emonhub

# ---------------------------------------------------------
# Install service
# ---------------------------------------------------------
echo "- installing emonhub.service"
sudo ln -sf $usrdir/emonhub/service/emonhub.service /lib/systemd/system
sudo systemctl enable emonhub.service
sudo systemctl restart emonhub.service

state=$(systemctl show emonhub | grep ActiveState)
echo "- Service $state"
# ---------------------------------------------------------
