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

module "peering" {
  source = "../../../modules/peering-consumer"

  project_name               = var.project_name
  aws_region                 = var.aws_region
  vpc_id                     = module.vpc.vpc_id
  route_table_ids            = module.vpc.route_table_ids
  shared_services_vpc_id     = var.shared_services_vpc_id
  shared_services_account_id = var.shared_services_account_id
  shared_services_vpc_cidr   = var.shared_services_vpc_cidr
  test_ec2_sg_id             = module.test_ec2.security_group_id
  enable_requester_dns       = var.enable_requester_dns
}
