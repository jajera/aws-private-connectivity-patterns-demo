provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      Pattern   = "lattice"
      Account   = "shared-services"
      ManagedBy = "terraform"
    }
  }
}
