"""
    Returns the millisecond portion of a date as an integer between 0 and 999.
    See https://docs.mongodb.com/manual/reference/operator/aggregation/millisecond/
    for more details
    :param expression: expression or variable of a Date, a Timestamp, or an ObjectID
    :return: Aggregation operator
    """
def MILLISECOND(expression: Any) -> object {
    return {'$millisecond': expression};
}