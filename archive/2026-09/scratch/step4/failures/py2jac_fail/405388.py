def uniq(iterable, key=lambda x: x):
    """
    Remove duplicates from an iterable. Preserves order.
    :type iterable: Iterable[Ord => A]
    :param iterable: an iterable of objects of any orderable type
    :type key: Callable[A] -> (Ord => B)
    :param key: optional argument; by default an item (A) is discarded
    if another item (B), such that A == B, has already been encountered and taken.
    If you provide a key, this condition changes to key(A) == key(B); the callable
    must return orderable objects.
    """
    keys = set()
    res = []
    for x in iterable:
        k = key(x)
        if k in keys:
            continue

        res.append(x)
        keys.add(k)
    return res

    # Enumerate the list to restore order lately; reduce the sorted list; restore order
    # def append_unique(acc, item):
    #     return acc if key(acc[-1][1]) == key(item[1]) else acc.append(item) or acc
    # srt_enum = sorted(enumerate(iterable), key=lambda item: key(item[1]))
    # return [item[1] for item in sorted(reduce(append_unique, srt_enum, [srt_enum[0]]))]

assert uniq([4, 4, 3, 5, 3, 2]) == [4, 3, 5, 2]
assert uniq([1, 1, 2, 3, 4, 4]) == [1, 2, 3, 4]
assert uniq((i for i in range(3)), lambda x: x) == [0, 1, 2]
assert uniq(['a', 'b', 'a']) == ['a', 'b']
assert uniq([1, 2, 1, 2, 2]) == [1, 2]
assert uniq([1,2]) == [1, 2]
assert uniq([1, 1, 2, 3, 3, 3, 4, 4, 4, 4, 4, 5, 6]) == [1, 2, 3, 4, 5, 6]
assert uniq(
    [2, 1, 2, 1, 2, 3, 4],
    lambda x: x) == [2, 1, 3, 4]
assert uniq(list('abcdefg')) == list('abcdefg')
assert uniq([1, 2, 3, 3, 4, 4, 4, 5]) == [1, 2, 3, 4, 5]
assert uniq(range(3), lambda x: x) == [0, 1, 2]
assert uniq([1, 1, 2, 3, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5]) == [1, 2, 3, 4, 5]
assert uniq([1, 2, 3, 4, 5]) == [1, 2, 3, 4, 5]
assert uniq([1, 1, 1, 2, 2, 2, 3]) == [1, 2, 3]
assert uniq([1, 1, 1, 1, 1]) == [1]
assert uniq(range(10)) == list(range(10))
assert uniq(
    ["a", "b", "a", "b", "c"]) == ["a", "b", "c"]
assert uniq([1,1,2,1,2,2]) == [1, 2]
assert uniq([1, 2, 3, 2, 1]) == [1, 2, 3]
assert uniq([0, 2, 1, 1, 0, 3, 1], lambda x: x) == [0, 2, 1, 3]
assert uniq([1, 1, 1, 1, 1, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 5]) == [1, 2, 3, 4, 5]
assert uniq(enumerate(range(3)), lambda x: x[0]) == [(0, 0), (1, 1), (2, 2)]
assert uniq(range(2)) == [0, 1]
assert uniq(iter([1, 2, 1, 3])) == [1, 2, 3]
assert uniq([1, 1, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5]) == [1, 2, 3, 4, 5]
assert uniq([1, 2, 3, 3, 3, 2, 1]) == [1, 2, 3]
assert uniq(
    ["a", "b", "a", "b", "c"],
    lambda x: x) == ["a", "b", "c"]
assert uniq(list('abbccc')) == list('abc')
assert uniq([]) == []
assert uniq([1, 2, 3, 4, 5, 6, 7, 8, 9, 8, 7, 6, 5, 4, 3, 2, 1]) == [1, 2, 3, 4, 5, 6, 7, 8, 9]
assert uniq(iter([3, 1, 2, 1])) == [3, 1, 2]
assert uniq(["a", "b", "a"]) == ["a", "b"]
assert uniq([3, 2, 3, 2, 3, 2, 1, 2]) == [3, 2, 1]
assert uniq([3, 1, 2, 2], lambda x: x) == [3, 1, 2]
assert uniq((i for i in range(3))) == [0, 1, 2]
assert uniq([1, 1, 1, 1]) == [1]
assert uniq([1, 2, 1, 3, 3]) == [1, 2, 3]
assert uniq('Hello') == ['H', 'e', 'l', 'o']
assert uniq([1, 2, 3]) == [1, 2, 3]
assert uniq(range(0)) == []
assert uniq(range(5)) == [0, 1, 2, 3, 4]
assert uniq([1, 1, 2, 2, 3, 3, 3]) == [1, 2, 3]
assert uniq("aaaabbbbccc") == ['a', 'b', 'c']
assert uniq([3, 3, 4, 5, 5, 5, 6, 6, 6]) == [3, 4, 5, 6]
assert uniq(range(10)) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
assert uniq([1, 2, 3, 4, 1, 2, 3, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5]) == [1, 2, 3, 4, 5]
assert uniq(list()) == list()
assert uniq([1, 1, 2, 3, 5, 8, 13, 21]) == [1, 2, 3, 5, 8, 13, 21]
assert uniq(enumerate(range(3))) == [(0, 0), (1, 1), (2, 2)]
assert uniq(range(1)) == [0]
assert uniq(range(4)) == list(range(4))
assert uniq(iter([2, 2, 1])) == [2, 1]
assert uniq(iter(["a", "a", "b", "b", "c", "c"]), lambda x: x[0]) == ["a", "b", "c"]
assert uniq(
    [2, 1, 2, 1, 2, 3, 4]) == [2, 1, 3, 4]
assert uniq(iter([1, 2, 3])) == [1, 2, 3]
assert uniq(uniq([1, 1.0, 2j, 3.0, 3, 1 + 2j, 1 + 0j])) == [1, 2j, 3.0, 1 + 2j]
assert uniq(range(100), lambda x: x % 5) == [0, 1, 2, 3, 4]
assert uniq([1, 2, 3, 2]) == [1, 2, 3]
assert uniq(range(3)) == [0, 1, 2]
assert uniq([4, 1, 2, 3, 4, 1, 2, 3], lambda x: x) == [4, 1, 2, 3]
assert uniq([1, 1.0, 2j, 3.0, 3, 1 + 2j, 1 + 0j]) == [1, 2j, 3.0, 1 + 2j]
assert uniq("abracadabra") == ["a", "b", "r", "c", "d"]
assert uniq([1, 1, 1]) == [1]
assert uniq(iter(["c", "c", "b", "b", "a", "a"]), lambda x: x) == ["c", "b", "a"]
assert uniq("mississippi") == ["m", "i", "s", "p"]
assert uniq(range(100)) == list(range(100))
assert uniq(range(0, 100, 10)) == list(range(0, 100, 10))
assert uniq([1, 2, 3, 4, 5, 1, 2]) == [1, 2, 3, 4, 5]
assert uniq(iter([])) == []
assert uniq(range(10), lambda x: x) == list(range(10))
assert uniq(iter(["a", "b", "c"])) == ["a", "b", "c"]
assert uniq([1, 2, 3, 3, 3, 3]) == [1, 2, 3]
assert uniq(range(4)) == [0, 1, 2, 3]
assert uniq([1]) == [1]
assert uniq(
    ['a', 'a', 'a', 'b', 'b', 'c', 'c', 'c', 'c', 'd']) == ['a', 'b', 'c', 'd']
assert uniq((1, 2, 1, 3, 3)) == [1, 2, 3]
assert uniq('123123123') == ['1', '2', '3']
assert uniq(['a', 'a', 'a', 'a', 'b', 'b', 'b', 'c']) == ['a', 'b', 'c']
assert uniq([3, 3, 4, 5, 5, 5]) == [3, 4, 5]
assert uniq(iter(["a", "a", "b", "b", "c", "c"]), lambda x: x) == ["a", "b", "c"]
assert uniq((4, 4, 3, 5, 3, 2)) == [4, 3, 5, 2]
assert uniq(
    [("a", 1), ("b", 2), ("c", 3), ("d", 4), ("e", 5), ("a", 6)],
    lambda x: x[0]) == [
    ("a", 1), ("b", 2), ("c", 3), ("d", 4), ("e", 5)]
assert uniq([3, 1, 2, 2]) == [3, 1, 2]
assert uniq([4, 1, 2, 3, 4, 1, 2, 3]) == [4, 1, 2, 3]
assert uniq(iter(["c", "b", "a"])) == ["c", "b", "a"]
assert uniq(iter([(1, 2), (2, 3), (3, 4), (1, 2)])) == [(1, 2), (2, 3), (3, 4)]
assert uniq(iter(["c", "c", "b", "b", "a", "a"]), lambda x: x[0]) == ["c", "b", "a"]
