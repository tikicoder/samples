# Creating an EC2 Image using EC2 Builder

Reminders
The EC2 Image builder has 2 phases a build and a test. During the build processes it creates the image, then it destroys the ec2 image and spins up a new instance for testing. If you have any scripts that are designed to run at first boot they will run on test. A current solution is to have a specific IAM Role that is only used for the EC2 Image Builder. If you do this you can do something similar:

           

iamRoleName=$(curl {{ ComponentAWSMetaUrl }}/iam/security-credentials/)
if [ "$${iamRoleName}" == "${iamRoleName}" ]; then                  
    echo "Still Building/Testing"
    logger -i -t "AIMComponent-3rdParty"  "${iamRoleName} Attached still building/testing image"
    exit;
fi