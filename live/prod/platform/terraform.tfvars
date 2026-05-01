project     = "openedx"
environment = "prod"
region      = "us-east-1"


cluster_version = "1.32"

# prod: production-grade instances, HA node groups
node_instance_type = "m5.xlarge"
node_min_size      = 3
node_max_size      = 10
node_desired_size  = 3

# prod: NO public endpoint — access only via internal VPN or bastion
cluster_endpoint_public_access = false
developer_cidrs                = []

# prod: all log types enabled
cluster_log_types          = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
cluster_log_retention_days = 90

efs_throughput_mode = "elastic"   # prod: consistent throughput under load


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

node_disk_size_gb = 50
