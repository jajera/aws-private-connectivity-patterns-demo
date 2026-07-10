provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      Pattern   = "cloudwan"
      Account   = "shared-services"
      ManagedBy = "terraform"
    }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = var.ram_region

  default_tags {
    tags = {
      Project   = var.project_name
      Pattern   = "cloudwan"
      Account   = "shared-services"
      ManagedBy = "terraform"
    }
  }
}
