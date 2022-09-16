The goal of this script is to auto create remedation tasks

# Samples

Spaces are not allowed in flag values
run only specific policies
main.sh --task-filter='[".*/policydefinitions/pol-cyderes-.*",".*/policydefinitions/securityteam_tenable$"]'


bash ./azure/scripts/cli/bash/samples/create_remediation_tasks/main.sh --task-filter='[".*/policydefinitions/securityteam_tenable*"]' --dry-run

bash ./azure/scripts/cli/bash/samples/create_remediation_tasks/main.sh --task-filter='[".*/policydefinitions/securityteam_tenable*"]' --task-filterodata='["pol-cyderes-","securityteam_tenable"]' --mg-ids="MainManagementGroup" --dry-run

bash ./azure/scripts/cli/bash/samples/create_remediation_tasks/main.sh --task-filter='[".*/policydefinitions/securityteam_tenable*"]' --task-filterodata='["pol-cyderes-","securityteam_tenable"]' --mg-ids="MainManagementGroup" --tenant-id=00000000-0000-0000-0000-000000000000 --dry-run