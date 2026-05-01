

output "file_system_id"    { value = aws_efs_file_system.main.id }
output "file_system_arn"   { value = aws_efs_file_system.main.arn }
output "access_point_id"   { value = aws_efs_access_point.openedx.id }
output "security_group_id" { value = aws_security_group.efs.id }
output "dns_name"          { value = aws_efs_file_system.main.dns_name }
output "kms_key_arn"       { value = aws_kms_key.efs.arn }

