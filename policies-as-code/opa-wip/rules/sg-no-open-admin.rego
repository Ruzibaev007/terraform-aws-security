package terraform.security

import data.terraform.lib

# SG resource with SSH open to world
exposed_sg {
  r := input.resource_changes[_]
  r.type == "aws_security_group"
  lib.has_after(r)
  sg := lib.get_after(r)

  some i
  sg.ingress[i].protocol == "tcp"
  sg.ingress[i].from_port <= 22
  sg.ingress[i].to_port >= 22
  (
    sg.ingress[i].cidr_blocks[_] == "0.0.0.0/0" or
    sg.ingress[i].ipv6_cidr_blocks[_] == "::/0"
  )
}

# Standalone SG rule resource
exposed_sg_rule {
  r := input.resource_changes[_]
  r.type == "aws_security_group_rule"
  lib.has_after(r)
  gr := lib.get_after(r)

  gr.type == "ingress"
  gr.protocol == "tcp"
  gr.from_port <= 22
  gr.to_port >= 22
  (
    gr.cidr_blocks[_] == "0.0.0.0/0" or
    gr.ipv6_cidr_blocks[_] == "::/0"
  )
}

deny[msg] {
  exposed_sg
  msg := "Security Group allows SSH from the world."
}

deny[msg] {
  exposed_sg_rule
  msg := "Security Group Rule allows SSH from the world."
}
