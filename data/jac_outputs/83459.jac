"""
    Evaluates one or more expressions and returns true if all of the expressions are true.
    See https://docs.mongodb.com/manual/reference/operator/aggregation/and/
    for more details
    """
def AND(*expressions: dict[str, str | int | float | bool | list[str | int | float]]) -> dict[str, list[dict[str, str | int | float | bool | list[str | int | float]]]] {
    return {'$and': list(expressions)};
}