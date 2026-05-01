project     = "openedx"
environment = "prod"
region      = "us-east-1"

vpc_cidr         = "10.30.0.0/16"
azs              = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnets   = ["10.30.1.0/24", "10.30.2.0/24", "10.30.3.0/24"]
private_subnets  = ["10.30.11.0/24", "10.30.12.0/24", "10.30.13.0/24"]
database_subnets = ["10.30.21.0/24", "10.30.22.0/24", "10.30.23.0/24"]

# prod: one NAT per AZ for high availability (~$130/month × 3 AZs)
single_nat_gateway      = false
flow_log_traffic_type   = "ALL"    # prod: full audit trail
flow_log_retention_days = 90

tags = {
  CostCenter = "engineering"
  Owner      = "platform-team"
}
