"""Recusrsively finds fields in script JSON and returns them as a list.
     Field has format: { "field":{ "name":"???", "kind":"???", "default":???, "description":"???" }}

    Args:
      struct: (dict) A dictionary representation fo the JSON script.
      path: (list) Stack that keeps track of recursion depth. Not used externally.

    Returns:
      fields: (list) A list of dictionaries representing each field struct found in the JSON.

  """
def json_get_fields(struct: dict[str, object] | list[object] | tuple[object], path: list[str | int] = []) -> dict[str, object] | list[object] {
    fields: dict[str, object] = {};
    path = path[:];
    if isinstance(struct, dict) {
        if 'field' in struct {
            field_obj = struct['field'] as dict[str, object];
            fields[field_obj['name'] as str] = field_obj;
        } else {
            for (key, value) in struct.items() {
                sub = json_get_fields(value as dict[str, object] | list[object] | tuple[object], path + [key]);
                fields.update(sub as dict[str, object]);
            }
        }
    } elif isinstance(struct, list) or isinstance(struct, tuple) {
        for (index, value) in enumerate(struct) {
            sub = json_get_fields(value as dict[str, object] | list[object] | tuple[object], path + [index]);
            fields.update(sub as dict[str, object]);
        }
    }
    if path == [] {
        vals = [v as dict[str, object] for v in fields.values()];
        return sorted(vals, key=lambda (f: dict[str, object]) { (f.get('order', 0) as int); });
    }
    return fields;
}