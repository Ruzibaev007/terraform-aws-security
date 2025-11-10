package terraform.lib

# Is there an "after" object in this change?
has_after(res) {
  res.change.after != null
}

# Get the "after" object safely.
get_after(res) := res.change.after

# Is this a create or update?
is_create_or_update(res) {
  some a
  a := res.change.actions[_]
  a == "create" or a == "update"
}
