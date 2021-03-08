# store state locally for shared IAC to avoid bootstrapping
terraform {
  backend "local" {
  }
}

