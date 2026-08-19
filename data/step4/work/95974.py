def _flatten_results_with_err(results_with_err):
    """flatten results with error

    Args:
        results_with_err ([(Error, result)]): results with error

    Returns:
        (Error, [result]): error, results
    """
    err_msg_list = []
    results = []
    for idx, (each_err, each_result) in enumerate(results_with_err):
        if each_err:
            err_msg_list.append('(%s/%s) e: %s' % (idx, len(results_with_err), each_err))
        results.append(each_result)

    err = None if not err_msg_list else Exception(','.join(err_msg_list))
    if err:
        return err, results

    return None, results

assert _flatten_results_with_err(
    [(None, {'a': 1}), (None, {'b': 2}), (None, {'c': 3}), (None, {'d': 4}), (None, {'e': 5})]) == (None, [{'a': 1}, {'b': 2}, {'c': 3}, {'d': 4}, {'e': 5}])
assert _flatten_results_with_err(
    [(None, 'r1'), (None, None)]
) == (None, ['r1', None])
assert _flatten_results_with_err(
    [(None, 'r1'), (None, 'r2'), (None, 'r3')]
) == (
    None,
    ['r1', 'r2', 'r3']
)
assert _flatten_results_with_err(
    [(None, 1), (None, 2), (None, 3), (None, 4)]) == (None, [1, 2, 3, 4])
assert _flatten_results_with_err(
    [
        (None, 1),
        (None, 2),
        (None, 3),
        (None, 4),
    ]
) == (None, [1, 2, 3, 4])
assert _flatten_results_with_err(
    [(None, 1), (None, 2), (None, 3), (None, 4), (None, 5)]) == (None, [1, 2, 3, 4, 5])
assert _flatten_results_with_err(
    [(None, 'a'), (None, 'b')]
) == (None, ['a', 'b'])
assert _flatten_results_with_err(
    [
        (None, 1),
        (None, 2),
        (None, 3),
    ]
) == (None, [1, 2, 3])
assert _flatten_results_with_err(
    [
        (None, 1),
        (None, 2),
        (None, 3),
        (None, 4),
        (None, 5),
    ]
) == (None, [1, 2, 3, 4, 5])
assert _flatten_results_with_err([(None, 1)]) == (None, [1])
assert _flatten_results_with_err([]) == (None, [])
assert _flatten_results_with_err(
    [
        (None, 1),
        (None, 2),
    ]
) == (None, [1, 2])
assert _flatten_results_with_err(
    [(None, 'a'), (None, 'b'), (None, 'c'), (None, 'd'), (None, 'e')]) == (None, ['a', 'b', 'c', 'd', 'e'])
assert _flatten_results_with_err(
    [(None, 'r1'), (None, 'r2')]
) == (None, ['r1', 'r2'])
assert _flatten_results_with_err(
    [(None, 1), (None, 2)]) == (None, [1, 2])
assert _flatten_results_with_err(
    [(None, 1), (None, 2), (None, 3)]) == (None, [1, 2, 3])
assert _flatten_results_with_err(
    [(None, "foo"), (None, "bar"), (None, "baz")]
) == (None, ["foo", "bar", "baz"])
assert _flatten_results_with_err(
    [
        (None, 100),
        (None, 200),
        (None, 300),
    ]
) == (
    None,
    [
        100,
        200,
        300,
    ],
)
assert _flatten_results_with_err(
    [
        (None, 'a'),
        (None, 'b'),
        (None, 'c')
    ]
) == (None, ['a', 'b', 'c'])
assert _flatten_results_with_err(
    [(None, 1), (None, 2), (None, 3)]
) == (None, [1, 2, 3])
assert _flatten_results_with_err(
    (
        (None, 1),
        (None, 2),
        (None, 3)
    )
) == (None, [1, 2, 3])
assert _flatten_results_with_err(
    [(None, None)]
) == (None, [None])
assert _flatten_results_with_err(
    [(None, 'a'), (None, 'b'), (None, 'c')]
) == (None, ['a', 'b', 'c'])
