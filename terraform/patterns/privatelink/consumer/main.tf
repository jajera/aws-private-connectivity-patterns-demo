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

module "privatelink" {
  source = "../../../modules/privatelink-consumer"

  project_name          = var.project_name
  endpoint_service_name = var.endpoint_service_name
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.private_subnet_ids
  test_ec2_sg_id        = module.test_ec2.security_group_id
}
