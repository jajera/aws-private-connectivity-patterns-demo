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
  connectivity_pattern = "lattice"
  aws_region           = var.aws_region
}

module "lattice" {
  source = "../../../modules/lattice-provider"

  project_name          = var.project_name
  aws_region            = var.aws_region
  alb_arn               = module.app.alb_arn
  alb_security_group_id = module.app.security_group_id
  vpc_id                = module.vpc.vpc_id
  consumer_account_ids  = [var.consumer_account_id]
}
