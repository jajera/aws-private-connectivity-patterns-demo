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
  connectivity_pattern = "privatelink"
  aws_region           = var.aws_region
}

module "privatelink" {
  source = "../../../modules/privatelink-provider"

  project_name       = var.project_name
  nlb_subnet_ids     = module.vpc.private_subnet_ids
  alb_arn            = module.app.alb_arn
  alb_listener_arn   = module.app.alb_listener_arn
  vpc_id             = module.vpc.vpc_id
  allowed_principals = ["arn:aws:iam::${var.consumer_account_id}:root"]
}
