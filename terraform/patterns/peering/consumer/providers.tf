provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      Pattern   = "peering"
      Account   = "consumer"
      ManagedBy = "terraform"
    }
  }
}
