project     = "openedx"
environment = "staging"
region      = "us-east-1"

cluster_version = "1.32"

node_instance_type = "t3.large"     # staging: bigger than dev, smaller than prod
node_min_size      = 1
node_max_size      = 5
node_desired_size  = 2

cluster_endpoint_public_access = true
developer_cidrs = ["10.0.0.0/8"]

cluster_log_types          = ["api", "audit", "authenticator"]
cluster_log_retention_days = 14

efs_throughput_mode = "bursting"


addon_versions = {
  kube_proxy = "v1.32.0-eksbuild.2"
  vpc_cni    = "v1.19.0-eksbuild.1"
  coredns    = "v1.11.4-eksbuild.2"
  ebs_csi    = "v1.37.0-eksbuild.1"
  efs_csi    = "v2.1.4-eksbuild.1"
}


tags = {
  CostCenter = "engineering"
  Owner      = "platform-team"
}

node_disk_size_gb = 30
