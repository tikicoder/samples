#!/bin/bash

temp_folder=$1

sudo cp $temp_folder/tiki_auto_cert_update.sh /usr/bin/tiki_auto_cert_update.sh
sudo chmod 755 /usr/bin/tiki_auto_cert_update.sh
sudo chown root:root /usr/bin/tiki_auto_cert_update.sh
sudo /usr/bin/tiki_auto_cert_update.sh

cd ~
# rm -Rf $temp_folder