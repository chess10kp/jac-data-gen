"""Create a configuration dictionary from a schema dictionary.
    The schema defines the valid configuration keys and their default
    values.  Each element of ``schema`` should be a tuple/list
    containing (default value,docstring,type) or a dict containing a
    nested schema."""
def create_default_config(schema: dict[str, dict | tuple]) -> dict {
    o = {};
    for (key, item) in schema.items() {
        if isinstance(item, dict) {
            o[key] = create_default_config(item);
        } elif isinstance(item, tuple) {
            (value, comment, item_type) = item;
            if isinstance(item_type, tuple) {
                item_type = item_type[0];
            }
            if value is None and (item_type == list or item_type == dict) {
                value = item_type();
            }
            if key in o {
                raise KeyError('Duplicate key in schema.');
            }
            o[key] = value;
        } else {
            raise TypeError(
                'Unrecognized type for schema dict element: %s %s' % (key, `type(item))
            );
        }
    }
    return o;
}