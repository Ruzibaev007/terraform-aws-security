
variable "enable_permissions_boundary" {
  type    = bool
  default = false # set true only when you want to create the boundary + sample role
}


module "permissions_boundary" {
  count  = var.enable_permissions_boundary ? 1 : 0
  source = "../../modules/iam/permission-boundary"
  name   = "tf-step5-permissions-boundary"
  allowed_kms_key_arns = [
     var.allowed_kms_key_arn
  ]
}


locals {
  permissions_boundary_arn = var.enable_permissions_boundary ? module.permissions_boundary[0].permissions_boundary_arn : null
}



resource "aws_iam_role" "devops" {
  count                = var.enable_permissions_boundary ? 1 : 0
  name                 = "devops-lab-role"
  assume_role_policy   = data.aws_iam_policy_document.assume_ec2.json
  permissions_boundary = local.permissions_boundary_arn
}

data "aws_iam_policy_document" "assume_ec2" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}
