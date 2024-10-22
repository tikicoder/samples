# cleanup-rbac-assignments

This is the start of potential scripts to help clean up rbac in Azure.

# Scripts

## Unknown Identities

This script is designed to go through every subscription that you have access to via the CLI and determine which Identities no longer exists.

It by default runs in dryrun/testmode. In this mode it will generate a report in json format of all the identities it will want to remove.

In normal mode it will remove the identities.

### details

DESCRIPTION
    This script is designed to go through every subscription that you have access to via the CLI and determine which Id
    entities no longer exists.
    The PARAMETER artifactSavePath is requrired


PARAMETERS
    -artifactSavePath <String>
        The location where the json file with the details oh what identities will be deleted or where deleted depending
         on if testmode is true or false
        This cannot be empty
        This file is always created.

    -testMode <Boolean>
        Should the application perform a dryrun or not. In this mode it will create an artifact file

    -subscriptionIdsStr <String>
        A comma seperated list of subscription ids to include

    -excludeSubscriptionIdsStr <String>
        A comma seperated list of subscription ids to exinclude

    -help
        Runs Get-Help -Full

### examples

-------------------------- EXAMPLE 1 --------------------------

PS > # Linux tmp location<br/>
# This just will run again all known subscriptions and save the data to the artifact save path.<br/>
PS> .\main.ps1 -artifactSavePath /tmp/rbac/



-------------------------- EXAMPLE 2 --------------------------

PS > # Windows User Location<br/>
# This just will run again all known subscriptions and save the data to the artifact save path.<br/>
PS> .\main.ps1 -artifactSavePath Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "rbac"

-------------------------- EXAMPLE 3 --------------------------

PS > # This will run against all known subscriptiosn and remove identities<br/>
PS> .\main.ps1 -testmode $false -artifactSavePath Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "rbac"



-------------------------- EXAMPLE 4 --------------------------

PS > # This will run against the 3 listed subscriptions and remove identities<br/>
PS> .\main.ps1 -testmode $false -subscriptionIdsStr "subid_1,subid_2,subid_3"-artifactSavePath Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "rbac"


-------------------------- EXAMPLE 5 --------------------------

PS > # This will run against the 1 listed subscriptions and NOT remove identities<br/>
PS> .\main.ps1 -subscriptionIdsStr "subid_1" -artifactSavePath Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "rbac"

-------------------------- EXAMPLE 6 --------------------------

PS > # This will run against all known subscriptiosn except the 1<br/>
PS> .\main.ps1 -excludeSubscriptionIdsStr "subid_1" -artifactSavePath Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "rbac"