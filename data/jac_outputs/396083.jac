"""
    Transforms appstruct to wps inputs.
    """
def appstruct_to_inputs(request: int, appstruct: dict[str, str | int | list[str] | list[int]]) -> list[tuple[str, str]] {
    inputs = [];
    for (key, values) in list(appstruct.items()) {
        if key in ['_async_check', 'csrf_token'] {
            continue;
        }
        if not isinstance(values, list) {
            values = [values];
        }
        for value in values {
            inputs.append((str(key).strip(), str(value).strip()));
        }
    }
    return inputs;
}