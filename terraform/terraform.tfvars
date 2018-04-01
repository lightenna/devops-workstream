terragrunt = {
  terraform {
    extra_arguments "apply_approve" {
      commands  = ["apply"]
      arguments = ["-auto-approve"]
    }

    extra_arguments "destroy_force" {
      commands  = ["destroy"]
      arguments = ["-force"]
    }
  }
}
