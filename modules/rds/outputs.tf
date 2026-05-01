
output "db_endpoint"     { value = aws_db_instance.main.endpoint }
output "db_host"         { value = aws_db_instance.main.address }
output "db_port"         { value = aws_db_instance.main.port }
output "db_name"         { value = aws_db_instance.main.db_name }
output "db_identifier"   { value = aws_db_instance.main.identifier }
output "db_connection"   { value = "${aws_db_instance.main.address}:${aws_db_instance.main.port}" }
output "security_group_id" { value = aws_security_group.rds.id }
output "kms_key_arn"     { value = aws_kms_key.rds.arn }

output "master_user_secret_arn" {
  description = "ARN of the AWS Secrets Manager secret holding the RDS master password"
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}


output "proxy_endpoint" {
  description = "RDS Proxy endpoint — empty string when proxy_role_arn is not set"
  value       = var.proxy_role_arn != "" ? aws_db_proxy.main[0].endpoint : ""
}
