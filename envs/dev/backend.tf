terraform {
  backend "s3" {
    bucket = "sctp-ce6-tfstate"
    key    = "ce6-group2-project-dev.tfstate"
    region = "ap-southeast-1"
  }
}
