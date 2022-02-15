#! /bin/sh

# References
# https://www.geeksforgeeks.org/5-ways-to-keep-your-ubuntu-system-clean/#:~:text=Uninstalling%20and%20Removing%20Unnecessary%20Applications,you%20can%20you%20simple%20command.&text=Press%20%E2%80%9CY%E2%80%9D%20and%20Enter.,the%20application%20will%20be%20removed.

cleanOldVersions=3
keepOldVersions=5

echo "Do not remove for safety"
sudo dpkg --list 'linux-image*' | grep "^ii" | grep "linux-image" | awk '{ print $2 }' | grep -b$keepOldVersions "$(uname -r)"

echo ""
echo "DO NOT DELETE version"
echo "linux-image-$(uname -r) or $(uname -r)"
uname -r

echo ""
echo "Suggested oldest version"
oldestKeepVersion=$(sudo dpkg --list 'linux-image*' | grep "^ii" | grep "linux-image" | awk '{ print $2 }' | grep -b$keepOldVersions "$(uname -r)" | head -1)
echo $oldestKeepVersion

echo ""
echo ""
echo "Suggest"
sudo dpkg --list 'linux-image*' | grep "^ii" | grep "linux-image" | awk '{ print $2 }' | grep -v "$(uname -r)" | head -$cleanOldVersions

oldestVersionInDeleteList=$(sudo dpkg --list 'linux-image*' | grep "^ii" | grep "linux-image" | awk '{ print $2 }' | grep -v "$(uname -r)" | head -$cleanOldVersions | grep -c "oldestKeepVersion")

if [ $oldestVersionInDeleteList -gt 0 ]; then

    echo "script unsafe to auto run. The suggested delete contains a version marked as safe (${oldestKeepVersion})"
    echo "You must manually process the request to ensure no unwanted versions deleted"
    exit
else
    echo "Should be safe to run, please verify suggested deleted against ones marked as keep"
fi

if ["$1" == "apply"]; then
    
    sudo dpkg --list 'linux-image*' | grep "^ii" | grep "linux-image" | awk '{ print $2 }' | grep -v "$(uname -r)" | head -$cleanOldVersions | xargs echo 
    # sudo dpkg --force-all -P <image<
    # example
    # sudo dpkg --force-all -P linux-image-4.4.0-1013-aws

    # sudo dpkg --list 'linux-image*' | grep "^ii" | grep "linux-image" | awk '{ print $2 }' | grep -v "$(uname -r)" | head -$cleanOldVersions | xargs sudo dpkg --force-all -P 
fi