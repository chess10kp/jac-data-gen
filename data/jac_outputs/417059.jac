"""get mongo query filter by recursion

    key_condictions is a list of (key, value, direction)

    >>> generate_spec([
    ...     ('a', '10', 1),
    ...     ('b', '20', 0),
    ... ])
    {'$or': [{'$and': [{'a': '10'}, {'b': {'$lt': '20'}}]}, {'a': {'$gt': '10'}}]}
    """
def generate_spec(key_condictions: Any) -> object {
    if not key_condictions {
        return {};
    }
    (key, value, direction) = key_condictions[0];
    gt_or_lt = '$gt' if (direction == 1) else '$lt';
    next_ordering = generate_spec(key_condictions[1:]);
    if next_ordering {
        return {
            '$or': [{'$and': [{key: value}, next_ordering]}, {key: {gt_or_lt: value}}]
        };
    } else {
        return {key: {gt_or_lt: value}};
    }
}