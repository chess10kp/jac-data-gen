"""
    Applies an expression to each item in an array and returns an array with the applied results.
    See https://docs.mongodb.com/manual/reference/operator/aggregation/map/
    for more details
    :param _input: An expression that resolves to an array.
    :param _as: A name for the variable that represents each individual element of the input array.
    :param _in: An expression that is applied to each element of the input array.
    :return: Aggregation operator
    """
def MAP(_input: Any, _as: Any, _in: Any) -> object {
    return {'$map': {'input': _input, 'as': _as, 'in': _in}};
}