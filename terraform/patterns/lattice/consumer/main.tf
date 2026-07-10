module "vpc" {
  source = "../../../modules/vpc"

  cidr_block   = var.vpc_cidr
  project_name = var.project_name
  account_name = "consumer"
  aws_region   = var.aws_region
}

module "test_ec2" {
  source = "../../../modules/test-ec2"

  vpc_id       = module.vpc.vpc_id
  subnet_id    = module.vpc.private_subnet_ids[0]
  project_name = var.project_name
  account_name = "consumer"
}

module "lattice" {
  source = "../../../modules/lattice-consumer"

  aws_region          = var.aws_region
  service_network_arn = var.lattice_service_network_arn
  resource_share_arn  = var.lattice_resource_share_arn
  vpc_id              = module.vpc.vpc_id
}
