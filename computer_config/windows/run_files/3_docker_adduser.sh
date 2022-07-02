#!/bin/bash

local_user=$1
local_user_groupid=$2
local_user_id=$3
home_path=$3

if [ $(grep -ic $local_user /etc/group) -lt 1 ]; then
  sudo groupadd --gid $local_user_groupid $local_user
fi

if [ $(grep -ic $local_user /etc/passwd) -lt 1 ]; then
  sudo adduser -G wheel --gid $local_user_groupid --uid $local_user_id $local_user --home $home_path
  ln -s $home_path "/home/$local_user"
fi



