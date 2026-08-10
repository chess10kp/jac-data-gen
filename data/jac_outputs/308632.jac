"""Descends into record using an array of fields, returning final value or None."""
def drill_for_value(record: dict[object, object], fields: list[object]) -> object | None {
    result: object | None = record;
    for f in fields {
        if result is None {
            break;
        }
        result = (result as dict[object, object]).get(f);
    }
    return result;
}