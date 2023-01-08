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
apt update

echo "installing or updating emonhub dependencies"
apt-get install -y python3-serial python3-configobj python3-pip python3-pymodbus bluetooth libbluetooth-dev python3-spidev

# this should not be needed on main user but could be re-enabled
# useradd -M -r -G dialout,tty -c "emonHub user" emonhub

# ---------------------------------------------------------
# EmonHub config file
# ---------------------------------------------------------
if [ ! -d /etc/emonhub ]; then
    echo "Creating /etc/emonhub directory"
    mkdir /etc/emonhub
    mkdir /var/log/emonhub
else
    echo "/etc/emonhub directory already exists"
fi

if [ ! -f /etc/emonhub/emonhub.conf ]; then
    cp $script_dir/conf/emonpi.default.emonhub.conf /etc/emonhub/emonhub.conf
    echo "No existing emonhub.conf configuration file found, installing default"
    
    # requires write permission for configuration from emoncms:config module
    chmod 666 /etc/emonhub/emonhub.conf
    echo "emonhub.conf permissions adjusted to 666"

    # Temporary: replace with update to default settings file
    sed -i "s/loglevel = DEBUG/loglevel = WARNING/" /etc/emonhub/emonhub.conf
    echo "Default emonhub.conf log level set to WARNING"
fi

# Fix emonhub log file permissions
if [ -d /var/log/emonhub ]; then
    echo "Setting ownership of /var/log/emonhub to $user"
    chown $user /var/log/emonhub
fi

if [ -f /var/log/emonhub/emonhub.log ]; then
    echo "Setting ownership of /var/log/emonhub/emonhub.log to $user and permissions to 644"
    chown $user:$user /var/log/emonhub/emonhub.log
    chmod 644 /var/log/emonhub/emonhub.log
fi
