
output "endpoint"          { value = "https://${aws_opensearch_domain.main.endpoint}" }
output "domain_name"       { value = aws_opensearch_domain.main.domain_name }
output "domain_arn"        { value = aws_opensearch_domain.main.arn }
output "security_group_id" { value = aws_security_group.opensearch.id }

