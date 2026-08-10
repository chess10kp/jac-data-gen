"""Drops the dict key if the value is None

    ES mapping does not allow None values and drops the document completely.
    """
def drop_nulls_in_dict(d: dict[str, object | None]) -> dict[str, object] {
    {k: v for (k, v) in d.items() if v is not None}
}