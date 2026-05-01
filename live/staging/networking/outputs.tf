#=======================================================================
# All outputs here are consumed by downstream layers via:
#   data "terraform_remote_state" "networking"
# Add any new value here when other layers need it.
# Never hardcode VPC IDs in other layers.
#=======================================================================

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr" {
  value = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  value = module.vpc.database_subnet_ids
}

output "nat_gateway_ids" {
  value = module.vpc.nat_gateway_ids
}
