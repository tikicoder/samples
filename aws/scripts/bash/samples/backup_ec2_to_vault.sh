instance_region=$(curl http://169.254.169.254/latest/meta-data/placement/region)
instance_id=$(curl http://169.254.169.254/latest/meta-data/instance-id)
default_backup_name="default"

backup_vault_name=$(aws backup list-backup-vaults --region "${instance_region}" | grep -i "${default_backup_name}" | grep "\BackupVaultName\":" | head -1 | awk '{ print $2 }' | tr -d "," | tr -d '"')
if [ "${backup_vault_name}" -z ]; then
 backup_vault_name=$(aws backup list-backup-vaults --region "${instance_region}" | grep "\BackupVaultName\":" | head -1 | awk '{ print $2 }' | tr -d "," | tr -d '"')
fi

account_id=$(aws sts get-caller-identity | grep "\Account\":" | awk '{ print $2 }' | tr -d "," | tr -d '"' )
instance_role_arn="arn:aws:iam::${account_id}:role/service-role/AWSBackupDefaultServiceRole"

idempotency_token=$(uuidgen -r)



aws backup start-backup-job \
--backup-vault-name "${backup_vault_name}" \
--resource-arn "arn:aws:ec2:${instance_region}:${account_id}:instance/${instance_id}" \
--iam-role-arn "${instance_role_arn}" \
--start-window-minutes 60 \
--complete-window-minutes 10080 \
--lifecycle DeleteAfterDays=30 \
--region "${instance_region}" \
--idempotency-token "${idempotency_token}" 
