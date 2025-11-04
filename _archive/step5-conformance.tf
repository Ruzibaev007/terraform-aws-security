resource "aws_config_conformance_pack" "step5_custom" {
  name          = "step5_custom"
  template_body = file("${path.module}/conformance/step5-custom.yaml")

  input_parameter {
    parameter_name  = "AllowedKmsKeyArns"
    parameter_value = var.allowed_kms_key_arn
  }
}
