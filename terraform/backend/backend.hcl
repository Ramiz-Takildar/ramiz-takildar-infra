bucket         = "ramiz-takildar-infra"
key            = "backend/terraform.tfstate"
region         = "us-east-1"
encrypt        = true

# State locking configuration
# For Terraform >= 1.6: Uses S3 native locking with lockfile
use_lockfile = true

# For Terraform < 1.6: Uncomment the line below and comment use_lockfile
# dynamodb_table = "terraform-locks"
