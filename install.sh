#!/bin/bash
# -------------------------------------------------------------
# emonHub install and update script
# -------------------------------------------------------------
# Assumes emonhub repository installed via git:
# git clone https://github.com/openenergymonitor/emonhub.git

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "EmonHub directory: $script_dir"

# User input: check username to install emonhub with
echo "Running apt update"
sudo apt update

echo "installing or updating emonhub dependencies"
sudo apt-get install -y python3-serial python3-configobj python3-pip python3-pymodbus bluetooth libbluetooth-dev python3-spidev
pip3 install paho-mqtt requests pybluez py-sds011 sdm_modbus minimalmodbus

# Custom rpi-rfm69 library used for SPI RFM69 Low Power Labs interfacer
pip3 install https://github.com/openenergymonitor/rpi-rfm69/archive/refs/tags/v0.3.0-oem-4.zip

# this should not be needed on main user but could be re-enabled
# sudo useradd -M -r -G dialout,tty -c "emonHub user" emonhub

# ---------------------------------------------------------
# EmonHub config file
# ---------------------------------------------------------
if [ ! -d /etc/emonhub ]; then
    echo "Creating /etc/emonhub directory"
    sudo mkdir /etc/emonhub
    sudo mkdir /var/log/emonhub
else
    echo "/etc/emonhub directory already exists"
fi

if [ ! -f /etc/emonhub/emonhub.conf ]; then
    sudo cp $script_dir/conf/emonpi.default.emonhub.conf /etc/emonhub/emonhub.conf
    echo "No existing emonhub.conf configuration file found, installing default"
    
    # requires write permission for configuration from emoncms:config module
    sudo chmod 666 /etc/emonhub/emonhub.conf
    echo "emonhub.conf permissions adjusted to 666"

    # Temporary: replace with update to default settings file
    sed -i "s/loglevel = DEBUG/loglevel = WARNING/" /etc/emonhub/emonhub.conf
    echo "Default emonhub.conf log level set to WARNING"
fi

# Fix emonhub log file permissions
if [ -d /var/log/emonhub ]; then
    echo "Setting ownership of /var/log/emonhub to $user"
    sudo chown $user /var/log/emonhub
fi

if [ -f /var/log/emonhub/emonhub.log ]; then
    echo "Setting ownership of /var/log/emonhub/emonhub.log to $user and permissions to 644"
    sudo chown $user:$user /var/log/emonhub/emonhub.log
    sudo chmod 644 /var/log/emonhub/emonhub.log
fi
