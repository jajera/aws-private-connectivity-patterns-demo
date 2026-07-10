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
  connectivity_pattern = "tgw"
  aws_region           = var.aws_region
}

module "tgw" {
  source = "../../../modules/tgw-provider"

  project_name               = var.project_name
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  route_table_ids            = module.vpc.route_table_ids
  consumer_account_ids       = [var.consumer_account_id]
  consumer_vpc_cidr          = var.consumer_vpc_cidr
  shared_services_vpc_cidr   = module.vpc.vpc_cidr_block
  consumer_tgw_attachment_id = var.consumer_tgw_attachment_id
  alb_security_group_id      = module.app.security_group_id
}
