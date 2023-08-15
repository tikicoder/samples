#!/bin/bash

sudo dnf update -y

sudo dnf install -y yum-utils

dnf config-manager --enable crb

sudo dnf install -y epel-release
sudo dnf install -y epel-next-release

sudo dnf update -y

sudo dnf remove --oldinstallonly --setopt installonly_limit=2 kernel