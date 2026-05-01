
project     = "openedx"
environment = "dev"
region      = "us-east-1"

cluster_version = "1.32"

node_instance_type = "t3.medium"   # dev: cheap general compute
node_min_size      = 1
node_max_size      = 3
node_desired_size  = 1

cluster_endpoint_public_access = true   # dev: allows kubectl from laptop
developer_cidrs = [
  "10.0.0.0/8",                         # internal VPN
  "172.16.0.0/12",
]

cluster_log_types          = ["api", "audit"]   # dev: subset to save cost
cluster_log_retention_days = 7

efs_throughput_mode = "bursting"   # dev: low sustained load, bursting is fine


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


node_disk_size_gb = 20
