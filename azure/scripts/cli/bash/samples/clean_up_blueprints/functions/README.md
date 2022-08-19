This is a script to force sync the blueprints. It will delete all the assignments and then all the policies part of the assignments. It will then reassign all the versions.


bash azure_samples/scripts/cli/bash/clean_up_blueprints/main.sh --skip-delete --skip-assignment --blueprint-filter="..." --subscription-exclude="..."

Run force delete
bash azure/scripts/cli/bash/samples/clean_up_blueprints/main.sh --skip-delete --run-forcedelete --skip-assignment-file