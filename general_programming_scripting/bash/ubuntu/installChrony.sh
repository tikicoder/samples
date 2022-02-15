#! /bin/sh

# References
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/set-time.html
# https://www.geeksforgeeks.org/5-ways-to-keep-your-ubuntu-system-clean/#:~:text=Uninstalling%20and%20Removing%20Unnecessary%20Applications,you%20can%20you%20simple%20command.&text=Press%20%E2%80%9CY%E2%80%9D%20and%20Enter.,the%20application%20will%20be%20removed.

sudo apt install chrony

echo "Add the following line to chrony.confg"

echo "server 169.254.169.123 prefer iburst minpoll 4 maxpoll 4" # This is AWS NTP server change this line with the required ntp server

echo "restart server"
echo "sudo /etc/init.d/chrony restart"

echo "run command the following command to view how far off the time is"
echo "chronyc tracking"
