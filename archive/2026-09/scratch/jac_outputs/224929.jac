"""
Get value from a model or dict or list with field.
Field must be a string or number value.
"""
def get_value_with_field(
    model: dict[str | int, object] | list[object] | object | None,
    field: str | int,
    null: object = None
) -> object {
    if not model {
        return null;
    }
    if isinstance(model, dict) {
        return model.get(field, null);
    }
    if isinstance(model, list) {
        try {
            index = int(field);
            if len(model) <= index {
                return null;
            }
            return list(model)[index];
        } except TypeError {
            return null;
        }
    }
    if isinstance(field, str) and hasattr(model, field) {
        return getattr(model, field);
    }
    return null;
}