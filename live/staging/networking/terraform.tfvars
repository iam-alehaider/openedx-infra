project     = "openedx"
environment = "staging"
region      = "us-east-1"

vpc_cidr         = "10.20.0.0/16"
azs              = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnets   = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
private_subnets  = ["10.20.11.0/24", "10.20.12.0/24", "10.20.13.0/24"]
database_subnets = ["10.20.21.0/24", "10.20.22.0/24", "10.20.23.0/24"]

single_nat_gateway      = true     # staging: still cost-saving
flow_log_traffic_type   = "REJECT"
flow_log_retention_days = 14

tags = {
  CostCenter = "engineering"
  Owner      = "platform-team"
}
