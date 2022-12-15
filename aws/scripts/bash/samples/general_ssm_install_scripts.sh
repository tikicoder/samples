# ubuntu 14
mkdir ~/tmp/ssm
cd /tmp/ssm
wget https://s3.us-east-1.amazonaws.com/amazon-ssm-us-east-1/latest/debian_amd64/amazon-ssm-agent.deb
sudo dpkg -i amazon-ssm-agent.deb
sudo status amazon-ssm-agent
cd /tmp
rm -Rf ~/tmp/ssm

# sudo start amazon-ssm-agent
# sudo status amazon-ssm-agent


# ubuntu 16 (No SNAP)
mkdir ~/tmp/ssm
cd /tmp/ssm
wget https://s3.us-east-1.amazonaws.com/amazon-ssm-us-east-1/latest/debian_amd64/amazon-ssm-agent.deb
sudo dpkg -i amazon-ssm-agent.deb
sudo systemctl status amazon-ssm-agent
cd /tmp
rm -Rf ~/tmp/ssm

# sudo systemctl enable amazon-ssm-agent
# sudo systemctl status amazon-ssm-agent

# centOS 7
# https://docs.aws.amazon.com/systems-manager/latest/userguide/agent-install-centos.html

sudo yum install -y https://s3.us-east-1.amazonaws.com/amazon-ssm-us-east-1/latest/linux_amd64/amazon-ssm-agent.rpm



# debiean 9/10

mkdir ~/tmp/ssm
cd /tmp/ssm
wget https://s3.us-east-1.amazonaws.com/amazon-ssm-us-east-1/latest/debian_amd64/amazon-ssm-agent.deb
sudo dpkg -i amazon-ssm-agent.deb
sudo systemctl status amazon-ssm-agent
cd /tmp
rm -Rf ~/tmp/ssm

# sudo systemctl enable amazon-ssm-agent
# sudo systemctl status amazon-ssm-agent