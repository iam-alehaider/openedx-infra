
project     = "openedx"
environment = "dev"
region      = "us-east-1"

vpc_cidr         = "10.10.0.0/16"
azs              = ["us-east-1a", "us-east-1b"]
public_subnets   = ["10.10.1.0/24", "10.10.2.0/24"]
private_subnets  = ["10.10.11.0/24", "10.10.12.0/24"]
database_subnets = ["10.10.21.0/24", "10.10.22.0/24"]

single_nat_gateway      = true    # dev: saves ~$130/month vs one per AZ
flow_log_traffic_type   = "REJECT" # dev: cheaper, only capture rejected traffic
flow_log_retention_days = 7

tags = {
  CostCenter = "engineering"
  Owner      = "platform-team"
}
