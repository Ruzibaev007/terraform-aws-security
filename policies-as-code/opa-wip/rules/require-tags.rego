package terraform.security

import data.terraform.lib

required_tags := {"Project", "Env"}

untagged_resource[res_type] {
  r := input.resource_changes[_]
  lib.has_after(r)
  a := lib.get_after(r)
  not a.tags
  res_type := r.type
}

missing_required_tag[[res_type, k]] {
  r := input.resource_changes[_]
  lib.has_after(r)
  a := lib.get_after(r)
  k := required_tags[_]
  not a.tags[k]
  res_type := r.type
}

deny[msg] {
  res_type := untagged_resource[_]
  msg := sprintf("Resource %s missing tags object.", [res_type])
}

deny[msg] {
  pair := missing_required_tag[_]
  res_type := pair[0]
  k := pair[1]
  msg := sprintf("Resource %s missing required tag %s.", [res_type, k])
}
