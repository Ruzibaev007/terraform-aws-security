package terraform.security

import data.terraform.lib


unencrypted_bucket {
  r := input.resource_changes[_]
  r.type == "aws_s3_bucket"
  lib.has_after(r)
  a := lib.get_after(r)

  not a.server_side_encryption_configuration
}

deny[msg] {
  unencrypted_bucket
  msg := "S3 bucket lacks server-side encryption configuration in plan."
}
