#!/bin/bash

temp_folder=$1

sudo cp $temp_folder/auto_cert_update.sh /usr/bin/tiki_auto_cert_update.sh
sudo chmod 755 /usr/bin/tiki_auto_cert_update.sh
sudo chown root:root /usr/bin/tiki_auto_cert_update.sh
sudo /usr/bin/tiki_auto_cert_update.sh


sudo dnf update -y

sudo dnf install -y yum-utils

dnf config-manager --enable crb

sudo dnf install -y epel-release
sudo dnf install -y epel-next-release

sudo dnf update -y

sudo dnf remove --oldinstallonly --setopt installonly_limit=2 kernel