"""
    For each element in `lst`, add it with its following element
    in the list. Returns all of the summed values in a list.

    >>> fix_3([1, '1', 2, None])
    <class 'TypeError'>
    <class 'TypeError'>
    <class 'TypeError'>
    <class 'IndexError'>
    []

    >>> fix_3([1, 2, 3, 4])
    <class 'IndexError'>
    [3, 5, 7]

    >>> fix_3([])
    []
    """
def fix_3(lst: list[object]) -> list[object] {
    sum_of_pairs: list[object] = [];
    for (i, _) in enumerate(lst) {
        try {
            sum_of_pairs.append(lst[i] + lst[i + 1]);
        } except TypeError as error {
            print(`type(error));
        } except IndexError as error {
            print(`type(error));
        }
    }
    return sum_of_pairs;
}