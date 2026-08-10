"""Returns datetime fields from a dict of fields

    """
def datetime_fields(fields: dict[str, dict[str, object]]) -> dict[str, dict[str, object]] {
    return {
        k: v
        for (k, v) in list(fields.items())
        if v.get("optype", False) == "datetime"
    };
}