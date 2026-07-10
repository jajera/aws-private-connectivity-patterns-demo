data "aws_caller_identity" "current" {}

module "vpc" {
  source = "../../../modules/vpc"

  cidr_block   = var.vpc_cidr
  project_name = var.project_name
  account_name = "shared-services"
  aws_region   = var.aws_region
}

module "app" {
  source = "../../../modules/shared-services-app"

  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_subnet_ids
  vpc_cidr             = module.vpc.vpc_cidr_block
  project_name         = var.project_name
  connectivity_pattern = "peering"
  aws_region           = var.aws_region
}

module "peering" {
  count  = var.peering_connection_id != "" ? 1 : 0
  source = "../../../modules/peering-provider"

  project_name          = var.project_name
  peering_connection_id = var.peering_connection_id
  consumer_vpc_cidr     = var.consumer_vpc_cidr
  route_table_ids       = module.vpc.route_table_ids
  alb_security_group_id = module.app.security_group_id
}
