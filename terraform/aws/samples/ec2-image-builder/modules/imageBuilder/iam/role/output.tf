output "roles" {
  value = aws_iam_role.ec2ImageBuilder_iam_role
}

output "role_profiles" {
  value = aws_iam_instance_profile.ec2ImageBuilder_pipeline_infastructure_iamInstanceProfile
}

