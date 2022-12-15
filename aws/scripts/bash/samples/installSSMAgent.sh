#! /bin/sh

# References
# https://www.geeksforgeeks.org/5-ways-to-keep-your-ubuntu-system-clean/#:~:text=Uninstalling%20and%20Removing%20Unnecessary%20Applications,you%20can%20you%20simple%20command.&text=Press%20%E2%80%9CY%E2%80%9D%20and%20Enter.,the%20application%20will%20be%20removed.

lsb_release -a

if [ -n "$(command -v amazon-ssm-agent)" ]; then
    echo "SSM Agent Installed"
    exit
fi

if [ -n "$(command -v amazon-ssm-agent.ssm-cli)" ]; then
    echo "SSM Agent Installed via snap"
    exit
fi

# if version 16.04 or newer it could have ssm installed already via snap, add code to check
sudo snap list amazon-ssm-agent 
if [ -n "$(command -v snap )" ]; then
    if [ $(sudo snap list amazon-ssm-agent | grep -ic amazon-ssm-agent) -gt 0 ]; then
        echo "SSM Agent Installed via snap"
        exit
    fi

fi

echo "preventing auto install until snap code is added"
exit
if [ "$1" == "apply" ]

    if [ -n "$(command -v snap )" ]; then
        sudo snap install amazon-ssm-agent --classic
    else
        mkdir /tmp/ssm
        cd /tmp/ssm

        wget https://s3.us-east-2.amazonaws.com/amazon-ssm-us-east-2/latest/debian_amd64/amazon-ssm-agent.deb
        sudo dpkg -i amazon-ssm-agent.deb
        cd ../
        rm -Rf ssm

    fi

    

    if [ -n "$(command -v systemctl )" ]; then
        if [ -n "$(command -v snap )" ]; then
            echo "If you get a Maximum timeout exceede please see the following URL"
            echo "https://docs.aws.amazon.com/systems-manager/latest/userguide/agent-install-ubuntu.html"
            echo "basically you need to one at a time Start, stop, and then status"
            echo "sudo systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service"
            echo "sudo systemctl stop snap.amazon-ssm-agent.amazon-ssm-agent.service"
            echo "sudo systemctl status snap.amazon-ssm-agent.amazon-ssm-agent.service"
            echo ""
            sudo snap list amazon-ssm-agent
            sudo snap services amazon-ssm-agent
            echo "If command return stopped, inactive, or disabled run"
            echo "sudo snap start amazon-ssm-agent"

            echo ""
            echo "To check on its status"
            echo "sudo snap services amazon-ssm-agent"
            exit

        fi

        sudo systemctl status amazon-ssm-agent
        echo "If command return stopped, inactive, or disabled run"
        echo "sudo systemctl enable amazon-ssm-agent"
        exit
    fi

    sudo status amazon-ssm-agent
    echo "If command return stopped, inactive, or disabled run"
    echo "sudo start amazon-ssm-agent"

fi