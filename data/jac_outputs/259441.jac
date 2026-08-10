""" for example a=[{"a": {"b": 2}}]
    walk_json_field_safe(a, 0, "a", "b") will get 2
    walk_json_field_safe(a, 0, "not_exist") will get None
    """
def walk_json_field_safe(`obj: list | dict, *fields: int | str) -> int | dict | list | str | float | bool | None {
    try {
        for f in fields {
            `obj = `obj[f];
        }
        return `obj;
    } except Exception {
        return None;
    }
}