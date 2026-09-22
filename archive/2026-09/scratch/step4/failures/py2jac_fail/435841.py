def reprsort(li):
    """
    sometimes, we need a way to get an unique ordering of any Python objects
    so here it is!
    (not quite "any" Python objects, but let's hope we'll never deal with that)
    """
    extli = list(zip(map(repr, li), range(len(li))))
    extli.sort()
    return [li[i[1]] for i in extli]

assert reprsort([-1, 0, 1]) == [-1, 0, 1]
assert reprsort( [[1,2],[2,3],[3,4],[2,1],[4,3],[5,6],[1,1],[4,4],[3,3]] ) == [[1,1],[1,2],[2,1],[2,3],[3,3],[3,4],[4,3],[4,4],[5,6]]
assert reprsort([3, 1.2, 1.0, 0, 3.2]) == [0, 1.0, 1.2, 3, 3.2]
assert reprsort(list(range(3))) == [0, 1, 2]
assert reprsort(list(range(4))) == [0, 1, 2, 3]
assert reprsort([1, 1.0, 1+0j]) == [1, 1+0j, 1.0]
assert reprsort([2, 2, 2, 1, 1]) == [1, 1, 2, 2, 2]
assert reprsort([3, 2, 1, 1, 2, 3, 3]) == [1, 1, 2, 2, 3, 3, 3]
assert reprsort([("foo", 1), ("bar", 1)]) == [("bar", 1), ("foo", 1)]
assert reprsort([1, 1, 1, 0]) == [0, 1, 1, 1]
assert reprsort([1, 1, 0, 0]) == [0, 0, 1, 1]
assert reprsort([1, 2, 2, 2]) == [1, 2, 2, 2]
assert reprsort([1, 2, 3, 4, 5, 6, 7]) == [1, 2, 3, 4, 5, 6, 7]
assert reprsort(['a', 'b', 'c', 'd']) == ['a', 'b', 'c', 'd']
assert reprsort([1, 2, 3, 4, 5, 6, 7, 8]) == [1, 2, 3, 4, 5, 6, 7, 8]
assert reprsort([10, [1, 2, 3]]) == [10, [1, 2, 3]]
assert reprsort([10, [1]]) == [10, [1]]
assert reprsort([10]) == [10]
assert reprsort(range(5)) == [0, 1, 2, 3, 4]
assert reprsort([3, 2, 1, 2, 3]) == [1, 2, 2, 3, 3]
assert reprsort(["foo", "bar", "baz"]) == ["bar", "baz", "foo"]
assert reprsort(list('defabc')) == list('abcdef')
assert reprsort([1, 2, 3, 2]) == [1, 2, 2, 3]
assert reprsort([2, 2, 2, 1]) == [1, 2, 2, 2]
assert reprsort(list("cba")) == list("abc")
assert reprsort([("foo", 1), ("bar", 1), ("foo", 2), ("bar", 2)]) == [
    ("bar", 1), ("bar", 2), ("foo", 1), ("foo", 2)
]
assert reprsort(list('abc')) == list('abc')
assert reprsort(list([3, 2, 1])) == list([1, 2, 3])
assert reprsort([3, 1, 2]) == [1, 2, 3]
assert reprsort(['b', 'a']) == ['a', 'b']
assert reprsort([("foo", 1), ("foo", 2)]) == [("foo", 1), ("foo", 2)]
assert reprsort(['a', 'a', 'b', 'b', 'c', 'd', 'd']) == ['a', 'a', 'b', 'b', 'c', 'd', 'd']
assert reprsort(['a', 'b', 'b']) == ['a', 'b', 'b']
assert reprsort(["foo", "bar", "baz", "a", "a"]) == ["a", "a", "bar", "baz", "foo"]
assert reprsort(range(1, 4)) == [1, 2, 3]
assert reprsort([1]) == [1]
assert reprsort(['a', 'c', 'b']) == ['a', 'b', 'c']
assert reprsort([10, [1, 2]]) == [10, [1, 2]]
assert reprsort(list(range(10))) == list(range(10))
assert reprsort(list([3, 1, 2])) == list([1, 2, 3])
assert reprsort([5, 5, 5, 5, 5]) == [5, 5, 5, 5, 5]
assert reprsort([1, 2, 3, 4, 5]) == [1, 2, 3, 4, 5]
assert reprsort([1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3]) == [
    1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3]
assert reprsort([{'y': 5}, {'x': 5}, {'x': 1}]) == [{'x': 1}, {'x': 5}, {'y': 5}]
assert reprsort([1,2,3]) == [1,2,3]
assert reprsort([2, 2, 1, 1, 1, 3, 3, 3, 3]) == [1, 1, 1, 2, 2, 3, 3, 3, 3]
assert reprsort([1, 2, 3, 4]) == [1, 2, 3, 4]
assert reprsort(['a', 'bb', 'ccc']) == ['a', 'bb', 'ccc']
assert reprsort([3.2, 1.2, 1.0, 0, 3.2]) == [0, 1.0, 1.2, 3.2, 3.2]
assert reprsort([1, 3, 3]) == [1, 3, 3]
assert reprsort(list([2, 3, 1])) == list([1, 2, 3])
assert reprsort([1, 0, 3]) == [0, 1, 3]
assert reprsort([0.0, 1.0]) == [0.0, 1.0]
assert reprsort(["bar", "foo"]) == ["bar", "foo"]
assert reprsort([1.0, 1.0, 2, 0]) == [0, 1.0, 1.0, 2]
assert reprsort(range(1, 3)) == [1, 2]
assert reprsort(['abc', 'def', 'ghi', '']) == ['', 'abc', 'def', 'ghi']
assert reprsort(["z", "b", "a", "c"]) == ["a", "b", "c", "z"]
assert reprsort([3.2, 1.2, 1.0]) == [1.0, 1.2, 3.2]
assert reprsort([3, 2, 1]) == [1, 2, 3]
assert reprsort(["foo", "foo"]) == ["foo", "foo"]
assert reprsort([4, 2, 1, 3]) == [1, 2, 3, 4]
assert reprsort([("a", 2), ("b", 3), ("a", 1)]) == [("a", 1), ("a", 2), ("b", 3)]
assert reprsort(["foo", "bar", "baz", "a"]) == ["a", "bar", "baz", "foo"]
assert reprsort([3.2, 1.2, 1.0, 0]) == [0, 1.0, 1.2, 3.2]
assert reprsort([]) == []
assert reprsort([5, 4, 3, 2, 1]) == [1, 2, 3, 4, 5]
assert reprsort([("a", 2), ("b", 3), ("a", 2), ("b", 3)]) == [("a", 2), ("a", 2), ("b", 3), ("b", 3)]
assert reprsort(['def', 'abc', 'ghi']) == ['abc', 'def', 'ghi']
assert reprsort([1, 2, 2, 1]) == [1, 1, 2, 2]
assert reprsort([0, 1, 2, 0]) == [0, 0, 1, 2]
assert reprsort(list("xyz")) == list("xyz")
assert reprsort([2, 3, 1, 2, 3, 3, 3, 2]) == [1, 2, 2, 2, 3, 3, 3, 3]
assert reprsort([1, 1.0]) == [1, 1.0]
assert reprsort(['abc', 'def', 'ghi']) == ['abc', 'def', 'ghi']
assert reprsort([10, 10]) == [10, 10]
assert reprsort([10, [1, 2, 3], [4, 5]]) == [10, [1, 2, 3], [4, 5]]
assert reprsort([3, 1, 1, 2]) == [1, 1, 2, 3]
assert reprsort([1, 1, 2]) == [1, 1, 2]
assert reprsort(['b', 1, 'a']) == ['a', 'b', 1]
assert reprsort(range(3)) == [0, 1, 2]
assert reprsort(["a", "b", "c", "d"]) == ["a", "b", "c", "d"]
assert reprsort(['a', 'b', 'b', 'c', 'd', 'd']) == ['a', 'b', 'b', 'c', 'd', 'd']
assert reprsort(['a', 'b', 'c']) == ['a', 'b', 'c']
assert reprsort(range(10)) == list(range(10))
assert reprsort([3.2, 1.2, -0.3, 1.0]) == [-0.3, 1.0, 1.2, 3.2]
assert reprsort(range(10)) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
assert reprsort(range(4)) == [0, 1, 2, 3]
assert reprsort(list([1, 2, 3])) == list([1, 2, 3])
assert reprsort([1, 2, 3, 2, 1]) == [1, 1, 2, 2, 3]
assert reprsort(['a', 'b', 'b', 'c', 'd']) == ['a', 'b', 'b', 'c', 'd']
assert reprsort(['a', 'a', 'b', 'c', 'd']) == ['a', 'a', 'b', 'c', 'd']
assert reprsort(['x', 'y', 'z']) == ['x', 'y', 'z']
assert reprsort(['a', 'a', 'a']) == ['a', 'a', 'a']
assert reprsort([10, []]) == [10, []]
assert reprsort([10, 11]) == [10, 11]
assert reprsort([1, 2, 3]) == [1, 2, 3]
assert reprsort(['b', 'a', 'c']) == ['a', 'b', 'c']
assert reprsort([1, 1, 2, 1, 1, 1, 1, 2, 1, 1]) == [1, 1, 1, 1, 1, 1, 1, 1, 2, 2]
assert reprsort([10, [1, 2, 3], [4]]) == [10, [1, 2, 3], [4]]
assert reprsort([0, 2, 1]) == [0, 1, 2]
assert reprsort(list("b2a1")) == list("12ab")
assert reprsort(["foo", "bar"]) == ["bar", "foo"]
assert reprsort([1, 2]) == [1, 2]
assert reprsort(list("a1b2")) == list("12ab")
assert reprsort(range(5)) == list(range(5))
assert reprsort([1, 2, 3, 4, 5, 6]) == [1, 2, 3, 4, 5, 6]
assert reprsort(['3', '1.2', '1.0', '0', '3.2']) == ['0', '1.0', '1.2', '3', '3.2']
assert reprsort([5, 4, 3, 2, 1, 1, 2, 3, 4, 5]) == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5]
assert reprsort([2, 1, 1.0, 0]) == [0, 1, 1.0, 2]
assert reprsort(list([2, 1, 3])) == list([1, 2, 3])
assert reprsort(list('bac')) == list('abc')
assert reprsort([1, 3, 2]) == [1, 2, 3]
assert reprsort(list("abc")) == list("abc")
assert reprsort([10, [1, 2, 3], []]) == [10, [1, 2, 3], []]
assert reprsort([1, 1, 1]) == [1, 1, 1]
assert reprsort([1, 1, 1, 2]) == [1, 1, 1, 2]
assert reprsort([-1, 0, 0, 1]) == [-1, 0, 0, 1]
assert reprsort([("a", 2), ("b", 3), ("a", 1), ("a", 2)]) == [("a", 1), ("a", 2), ("a", 2), ("b", 3)]
assert reprsort([1, 2, 3, 4, 5, 6, 7, 8, 9]) == [1, 2, 3, 4, 5, 6, 7, 8, 9]
assert reprsort(list(range(1, 3))) == [1, 2]
assert reprsort(["foo", "bar", "foo"]) == ["bar", "foo", "foo"]
assert reprsort([3, 2, 1, 1, 3]) == [1, 1, 2, 3, 3]
assert reprsort([1, 3, 2, 1]) == [1, 1, 2, 3]
assert reprsort(["23", "1"]) == ["1", "23"]
assert reprsort([1, 1, 1, 1, 1]) == [1, 1, 1, 1, 1]
