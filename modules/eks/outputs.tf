

output "cluster_id"                  { value = aws_eks_cluster.main.id }
output "cluster_name"                { value = aws_eks_cluster.main.name }
output "cluster_endpoint"            { value = aws_eks_cluster.main.endpoint }
output "cluster_ca_certificate"      { value = aws_eks_cluster.main.certificate_authority[0].data }
output "cluster_version"             { value = aws_eks_cluster.main.version }
output "oidc_provider_arn"           { value = aws_iam_openid_connect_provider.eks.arn }
output "oidc_provider_url"           { value = aws_iam_openid_connect_provider.eks.url }
output "node_security_group_id"      { value = aws_security_group.nodes.id }
output "cluster_security_group_id"   { value = aws_security_group.cluster.id }
output "ebs_csi_role_arn"            { value = aws_iam_role.ebs_csi.arn }
output "efs_csi_role_arn"            { value = aws_iam_role.efs_csi.arn }
output "cluster_autoscaler_role_arn" { value = aws_iam_role.cluster_autoscaler.arn }
output "openedx_s3_role_arn"         { value = aws_iam_role.openedx_s3.arn }
output "node_role_arn"               { value = aws_iam_role.nodes.arn }
output "kms_key_arn"                 { value = aws_kms_key.eks.arn }

