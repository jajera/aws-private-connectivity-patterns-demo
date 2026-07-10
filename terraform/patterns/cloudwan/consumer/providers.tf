provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      Pattern   = "cloudwan"
      Account   = "consumer"
      ManagedBy = "terraform"
    }
  }
}

provider "aws" {
  alias  = "apse1"
  region = var.sandbox_aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      Pattern   = "cloudwan"
      Account   = "consumer"
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
      Account   = "consumer"
      ManagedBy = "terraform"
    }
  }
}
