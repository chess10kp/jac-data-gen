def find_symmetric_difference(list1, list2):
    """
    show difference
    :param list1:
    :type list1:
    :param list2:
    :type list2:
    :return:
    :rtype:
    """

    difference = set(list1).symmetric_difference(set(list2))
    list_difference = list(difference)

    return list_difference

assert find_symmetric_difference(
    [1, 1, 2, 2, 3],
    [1, 1, 2, 2, 3]
) == []
assert find_symmetric_difference(
    [1, 2, 3, 4, 5],
    [5, 4, 3, 2, 1]
) == []
assert find_symmetric_difference(
    [1, 1, 2, 2, 3, 4, 5],
    [1, 1, 2, 2, 3, 4, 5]
) == []
assert find_symmetric_difference( [1, 2, 3, 4, 5], [5, 6, 7, 8, 9] ) == [1, 2, 3, 4, 6, 7, 8, 9]
assert find_symmetric_difference(
    ['apple', 'apple', 'apple'],
    ['apple', 'apple', 'apple']
) == []
assert find_symmetric_difference(
    [1, 2, 3], [1, 2, 3]) == []
assert find_symmetric_difference(
    [1, 1, 2, 2, 3],
    [1, 1, 2, 2]
) == [3]
assert find_symmetric_difference(
    [1, 2, 3, 5],
    [1, 2, 3, 4, 5]
) == [4]
assert find_symmetric_difference(
    ['apple', 'apple', 'apple', 'banana'],
    ['apple', 'apple', 'apple', 'banana']
) == []
assert find_symmetric_difference(set([1, 2, 3, 5, 7]), set([])) == [1, 2, 3, 5, 7]
assert find_symmetric_difference(
    [1, 2, 3, 4, 5],
    [5, 2, 1, 7, 4]
) == [3, 7]
assert find_symmetric_difference([], [1, 2, 3, 4, 5]) == [1, 2, 3, 4, 5]
assert find_symmetric_difference(
    [1, 2, 3, 4, 5],
    [1, 2, 5, 7, 5]
) == [3, 4, 7]
assert find_symmetric_difference( [1, 2, 3, 4, 5], [2, 5, 6, 7, 9] ) == [1, 3, 4, 6, 7, 9]
assert find_symmetric_difference(
    [],
    [2, 3]) == [2, 3]
assert find_symmetric_difference(
    [1, 2, 3], [2, 3, 4]) == [1, 4]
assert find_symmetric_difference(
    [1, 2, 3, 4], [5, 6, 7, 8]) == [1, 2, 3, 4, 5, 6, 7, 8]
assert find_symmetric_difference([1, 2, 3, 4, 5], [1, 2, 3, 4, 5]) == []
assert find_symmetric_difference(
    [1, 1, 2, 2, 3, 4, 5, 6],
    [1, 1, 2, 2, 3, 4, 5, 6]
) == []
assert find_symmetric_difference(
    [1, 2, 3, 4, 5],
    [5, 2, 10, 10]
) == [1, 3, 4, 10]
assert find_symmetric_difference(
    ['apple', 'orange','mango'],
    ['banana', 'orange','mango']
) == ['banana', 'apple']
assert find_symmetric_difference( [], [1, 2, 3, 4, 5] ) == [1, 2, 3, 4, 5]
assert find_symmetric_difference( [1, 2, 3, 4, 5], [1, 2, 3, 4, 5, 5, 5, 5] ) == []
assert find_symmetric_difference(
    [1, 2, 3, 4, 5],
    [1]
) == [2, 3, 4, 5]
assert find_symmetric_difference(
    [1, 2, 3, 4],
    [5, 6, 7, 8]
) == [1, 2, 3, 4, 5, 6, 7, 8]
assert find_symmetric_difference(
    [1, 2, 3, 4, 5],
    [5, 2, 10]
) == [1, 3, 4, 10]
assert find_symmetric_difference(
    [],
    []
) == []
assert find_symmetric_difference(
    [1, 2, 3, 4, 5],
    [5, 2, 10, 10, 10]
) == [1, 3, 4, 10]
assert find_symmetric_difference(
    [1, 2, 3, 4],
    [1, 2, 3, 4, 5]
) == [5]
assert find_symmetric_difference(
    ['apple', 'orange','mango', 'apple'],
    ['banana', 'orange', 'apple','mango']
) == ['banana']
assert find_symmetric_difference([1, 2, 3, 4, 5], [6, 7, 8, 9, 10]) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
assert find_symmetric_difference(
    [1, 2, 3, 4], [1, 2, 3, 4]) == [], "Should be []"
assert find_symmetric_difference(
    [1, 2, 3, 4, 5],
    [1, 2, 3, 4, 5]
) == []
assert find_symmetric_difference(
    [1, 2, 3, 4, 5],
    [1, 2, 3, 4]
) == [5]
assert find_symmetric_difference(
    [1, 2, 3, 4], [3, 4, 5, 6]) == [1, 2, 5, 6], "Should be [1, 2, 5, 6]"
assert find_symmetric_difference(
    [1, 2, 3, 4], []) == [1, 2, 3, 4], "Should be [1, 2, 3, 4]"
assert find_symmetric_difference([1, 2, 3, 4, 5], []) == [1, 2, 3, 4, 5]
assert find_symmetric_difference(
    [1, 2, 3, 4],
    [1, 2, 3, 4]
) == []
assert find_symmetric_difference(
    [1],
    [1, 2, 3, 4, 5]
) == [2, 3, 4, 5]
assert find_symmetric_difference(
    [1, 2, 3, 4, 5], [2, 3, 5, 6, 7]) == [1, 4, 6, 7], "Should be [1, 4, 6, 7]"
assert find_symmetric_difference(
    [],
    [1, 2, 3, 4, 5]
) == [1, 2, 3, 4, 5]
assert find_symmetric_difference( [1, 2, 3, 4, 5], [] ) == [1, 2, 3, 4, 5]
assert find_symmetric_difference(
    [1, 2, 3, 4, 5, 6, 7, 8, 9],
    [5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
) == [1, 2, 3, 4, 10, 11, 12, 13, 14]
assert find_symmetric_difference(
    [1, 2, 3],
    []
) == [1, 2, 3]
assert find_symmetric_difference( [1, 2, 3, 4, 5], [1, 2, 3, 4, 5] ) == []
assert find_symmetric_difference([6, 7, 8, 9, 10], [1, 2, 3, 4, 5]) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
assert find_symmetric_difference(
    [1, 1, 2, 2, 3, 3, 4, 5, 6, 7],
    [5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
) == [1, 2, 3, 4, 8, 9, 10, 11, 12, 13, 14]
assert find_symmetric_difference(
    [1, 2, 3, 4, 5],
    [4, 5, 1, 2, 3]
) == []
assert find_symmetric_difference(
    [1, 1, 2, 2, 3, 4, 5],
    [1, 1, 2, 2, 3, 4, 5, 6]
) == [6]
assert find_symmetric_difference(
    [], [1, 2, 3, 4]) == [1, 2, 3, 4], "Should be [1, 2, 3, 4]"
assert find_symmetric_difference(
    ['apple', 'orange', 'carrot'],
    ['banana', 'orange', 'apple']
) == ['banana', 'carrot']
assert find_symmetric_difference(set([]), set([1, 2, 3, 5, 7])) == [1, 2, 3, 5, 7]
