This is a script to force sync the blueprints. It will delete all the assignments and then all the policies part of the assignments. It will then reassign all the versions.


bash azure_samples/scripts/cli/bash/clean_up_blueprints/main.sh --skip-delete --skip-assignment --blueprint-filter="..." --subscription-exclude="..."

Run force delete
bash azure/scripts/cli/bash/samples/clean_up_blueprints/main.sh --skip-delete --run-forcedelete --skip-assignment-file

# Samples

Run just the assignment
bash azure/scripts/cli/bash/samples/clean_up_blueprints/main.sh --skip-assignment --skip-assignment-file --skip-delete --run-assignment

This will go through and just validate everything, and generate the existing_assignments.txt file. It also skips the assignment.
bash azure_samples/scripts/cli/bash/clean_up_blueprints/main.sh --skip-delete --skip-assignment --blueprint-filter="bp-base,bp-caf-foundation,bp-cis,bp-inherit_tags_subscription,bp-ISO-27001-base,bp-ISO-27001-shared_services,bp-nist-800-171" --subscription-exclude="12121212-4541-4521-1245-121212121212,12121212-4541-4521-1245-121212121212"



