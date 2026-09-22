"""Set which attributes should have values inferred from ancestral taxa."""
def set_attributes_to_descend(
    meta: dict[str, dict[str, str | bool | int]],
    traverse_limit: int
) -> tuple[set[str], dict[str, int]] {
    desc_attrs = set();
    desc_attr_limits = {};
    for (key, value) in meta.items() {
        if "traverse" in value and value["traverse"] {
            if (
                "traverse_direction" not in value
                or value["traverse_direction"] in ("down", "both")
            ) {
                desc_attrs.add(key);
                if "traverse_limit" in value {
                    desc_attr_limits.update({key: value["traverse_limit"]});
                } else {
                    desc_attr_limits.update({key: traverse_limit});
                }
            }
        }
    }
    return (desc_attrs, desc_attr_limits);
}