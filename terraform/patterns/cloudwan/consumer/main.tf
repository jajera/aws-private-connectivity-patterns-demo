module "vpc_workloads" {
  source = "../../../modules/vpc"

  cidr_block   = var.workloads_vpc_cidr
  project_name = var.project_name
  account_name = "consumer-workloads"
  aws_region   = var.aws_region
}

module "test_ec2_workloads" {
  source = "../../../modules/test-ec2"

  vpc_id       = module.vpc_workloads.vpc_id
  subnet_id    = module.vpc_workloads.private_subnet_ids[0]
  project_name = var.project_name
  account_name = "consumer-workloads"
}

module "cloudwan_workloads" {
  source = "../../../modules/cloudwan-consumer"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project_name             = var.project_name
  core_network_id          = var.core_network_id
  core_network_arn         = var.core_network_arn
  resource_share_arn       = var.core_network_resource_share_arn
  ram_region               = var.ram_region
  accept_ram_share         = true
  segment_name             = "workloads"
  vpc_id                   = module.vpc_workloads.vpc_id
  subnet_ids               = module.vpc_workloads.private_subnet_ids
  route_table_ids          = module.vpc_workloads.route_table_ids
  shared_services_vpc_cidr = var.shared_services_vpc_cidr
  test_ec2_sg_id           = module.test_ec2_workloads.security_group_id
}

module "vpc_sandbox" {
  source = "../../../modules/vpc"

  providers = {
    aws = aws.apse1
  }

  cidr_block   = var.sandbox_vpc_cidr
  project_name = var.project_name
  account_name = "consumer-sandbox"
  aws_region   = var.sandbox_aws_region
}

module "test_ec2_sandbox" {
  source = "../../../modules/test-ec2"

  providers = {
    aws = aws.apse1
  }

  vpc_id       = module.vpc_sandbox.vpc_id
  subnet_id    = module.vpc_sandbox.private_subnet_ids[0]
  project_name = var.project_name
  account_name = "consumer-sandbox"
}

module "cloudwan_sandbox" {
  source = "../../../modules/cloudwan-consumer"

  providers = {
    aws           = aws.apse1
    aws.us_east_1 = aws.us_east_1
  }

  project_name             = var.project_name
  core_network_id          = var.core_network_id
  core_network_arn         = var.core_network_arn
  resource_share_arn       = var.core_network_resource_share_arn
  ram_region               = var.ram_region
  accept_ram_share         = false
  segment_name             = "sandbox"
  vpc_id                   = module.vpc_sandbox.vpc_id
  subnet_ids               = module.vpc_sandbox.private_subnet_ids
  route_table_ids          = module.vpc_sandbox.route_table_ids
  shared_services_vpc_cidr = var.shared_services_vpc_cidr
  test_ec2_sg_id           = module.test_ec2_sandbox.security_group_id
}
