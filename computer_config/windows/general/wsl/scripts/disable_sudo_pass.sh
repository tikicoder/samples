#!/bin/bash

echo "`whoami` ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/`whoami`
sudo chmod 0440 /etc/sudoers.d/`whoami`
