def unique(data):
    """
     in python 3: TypeError: '<' not supported between instances of 'int' and 'str'
     need to keep the same Type of member in List
    """
    data.sort()
    l = len(data) - 1
    i = 0
    while i < l:
        if (data[i] == data[i + 1]):
            del data[i]
            i -= 1
            l -= 1
        i += 1
    return data

assert unique(
    ['A', 'B', 'B', 'C']) == ['A', 'B', 'C']
assert unique(
    [2, 4, 4, 2, 4, 4, 4, 4, 3, 3, 2, 3, 4, 4, 4]) == [2, 3, 4]
assert unique([3, 3, 2, 3, 1, 3, 4]) == [1, 2, 3, 4]
assert unique(
    [1, 1, 1]
) == [1], "unique([1, 1, 1])"
assert unique(['a', 'b', 'c', 'd', 'e']) == ['a', 'b', 'c', 'd', 'e']
assert unique(['1', '2', '3', '1', '2', '3', '1', '2', '3', '1', '2', '3']) == ['1', '2', '3']
assert unique(list(range(10))) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
assert unique(
    []
) == [], "unique([])"
assert unique(
    ['A', 'A', 'A', 'A']) == ['A']
assert unique([1, 1, 1, 1, 1]) == [1]
assert unique(unique([1, 1, 2, 2, 3])) == [1, 2, 3]
assert unique(unique([1, 2, 3, 3, 4, 5])) == [1, 2, 3, 4, 5]
assert unique([1, 2, 2, 2, 3, 3]) == [1, 2, 3]
assert unique(['a', 'a', 'a', 'b', 'a', 'a']) == ['a', 'b']
assert unique([2, 2, 2, 2, 2, 2]) == [2]
assert unique(unique([1, 2, 3, 4, 5])) == [1, 2, 3, 4, 5]
assert unique(
    ['b', 'b', 'b', 'b', 'b', 'b', 'b', 'b', 'b', 'b', 'b', 'b', 'b', 'b', 'b', 'b', 'b', 'b', 'b', 'b', 'b', 'b', 'b', 'b']) == ['b']
assert unique([1, 2, 3, 2, 2, 1, 2, 1]) == [1, 2, 3]
assert unique(
    [1, 2, 2, 3, 4, 4, 4]) == [1, 2, 3, 4]
assert unique(["A", "B", "A", "B", "C"]) == ["A", "B", "C"]
assert unique(
    [1, 2, 3, 3, 2, 1]
) == [1, 2, 3]
assert unique(
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
assert unique(['a', 'b', 'c', 'd', 'c', 'b', 'a']) == ['a', 'b', 'c', 'd']
assert unique(['A', 'A', 'A', 'A', 'B', 'B', 'B', 'C']) == ['A', 'B', 'C']
assert unique(unique([1, 2, 3, 3, 4, 4, 5, 5])) == [1, 2, 3, 4, 5]
assert unique(["A", "B", "C", "A", "B", "C"]) == ["A", "B", "C"]
assert unique(
    ['a', 'a', 'b', 'c', 'c', 'd', 'd', 'd', 'e']) == ['a', 'b', 'c', 'd', 'e']
assert unique(['1', '2', '3', '1', '2', '3']) == ['1', '2', '3']
assert unique(
    [1, 2, 3, 4, 5, 6, 6]) == [1, 2, 3, 4, 5, 6]
assert unique([5, 5, 5, 5, 5, 5]) == [5]
assert unique(
    [2, 4, 4, 2, 4, 4, 4, 4, 3, 3, 2, 3, 4, 4, 4, 4, 5, 3, 4, 5]) == [2, 3, 4, 5]
assert unique([1, 1, 1, 1, 1, 1]) == [1]
assert unique(["A", "B", "C", "A", "B", "C", "A", "B", "C"]) == ["A", "B", "C"]
assert unique([1, 1, 2, 2, 3, 3, 3]) == [1, 2, 3]
assert unique(unique([1, 2, 3, 3, 4, 4, 5])) == [1, 2, 3, 4, 5]
assert unique(['a']) == ['a']
assert unique(["hi", "bye", "hi"]) == ["bye", "hi"]
assert unique(
    [1, 2, 3, 2, 3, 2, 3, 4]) == [1, 2, 3, 4]
assert unique(["  A", "  B", "  C"]) == ["  A", "  B", "  C"]
assert unique([1, 1, 1, 2, 2, 2, 3, 3, 3, 1, 1, 2, 3, 3]) == [1, 2, 3]
assert unique(list('aAa')) == list('Aa')
assert unique(
    [1.1, 1.1, 1.2, 2.2]) == [1.1, 1.2, 2.2]
assert unique(unique([1, 2, 3, 3, 3, 3, 4, 5, 5, 5, 5, 5, 5, 5])) == [1, 2, 3, 4, 5]
assert unique([[], [1]]) == [[], [1]]
assert unique(['A', 'A', 'A', 'A', 'B', 'B', 'B', 'C', 'C', 'C']) == ['A', 'B', 'C']
assert unique(['a', 'a', 'a']) == ['a']
assert unique(list('a')) == list('a')
assert unique(['a', 'b', 'a', 'c']) == ['a', 'b', 'c']
assert unique([1, 2, 2, 3, 3, 3]) == [1, 2, 3]
assert unique(['a', 'b', 'c', 'd']) == ['a', 'b', 'c', 'd']
assert unique(unique(["a", "a", "a", "b", "b", "c"])) == ["a", "b", "c"]
assert unique([1, 2, 3, 1]) == [1, 2, 3]
assert unique([1, 1]) == [1]
assert unique(unique([1, 1, 2, 3, 3, 3, 4])) == [1, 2, 3, 4]
assert unique(
    [1, 2, 3, 2, 3, 4]) == [1, 2, 3, 4]
assert unique([2.1, 2.2, 2.3, 2.3, 2.2, 2.1]) == [2.1, 2.2, 2.3]
assert unique([1, 2, 1, 1, 2]) == [1, 2]
assert unique([1, 2, 3, 4, 5, 6]) == [1, 2, 3, 4, 5, 6]
assert unique([1, 2, 3, 4, 5]) == [1, 2, 3, 4, 5]
assert unique(
    [1, 2, 2, 3, 4, 5, 6]) == [1, 2, 3, 4, 5, 6]
assert unique(['a', 'a', 'a', 'b', 'a', 'b', 'a', 'c']) == ['a', 'b', 'c']
assert unique(['hello', 'hi', 'hello']) == ['hello', 'hi']
assert unique(['a', 'b', 'c']) == ['a', 'b', 'c']
assert unique(unique([])) == []
assert unique(unique([1, 1, 1, 1, 1, 1])) == [1]
assert unique(unique([1, 1, 2, 2, 3, 4, 4, 4])) == [1, 2, 3, 4]
assert unique([]) == []
assert unique([1, 1, 2, 2, 3, 3]) == [1, 2, 3]
assert unique([1, 1, 1, 2, 2, 2, 3, 3, 3]) == [1, 2, 3]
assert unique(unique([1, 2, 3])) == [1, 2, 3]
assert unique(list('123123123123123')) == ['1', '2', '3']
assert unique(
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 2]) == [1, 2]
assert unique(list('123123')) == ['1', '2', '3']
assert unique(
    [1, 2, 2, 3, 3, 3, 4, 4, 4, 4, 4]
) == [1, 2, 3, 4]
assert unique(list('AaAa')) == list('Aa')
assert unique(list('123123123123')) == ['1', '2', '3']
assert unique([1, 2, 3, 2, 1]) == [1, 2, 3]
assert unique([1, 2, 3, 2, 1, 3, 2, 2]) == [1, 2, 3]
assert unique(
    [1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 5]) == [1, 2, 3, 4, 5]
assert unique([1]) == [1]
assert unique([1, 1, 2, 3, 3, 3, 4]) == [1, 2, 3, 4]
assert unique(['A', 'B', 'C', 'D', 'E']) == ['A', 'B', 'C', 'D', 'E']
assert unique([1, 2, 1]) == [1, 2]
assert unique(['a', 'a', 'a', 'a']) == ['a']
assert unique([1, 2, 3, 4, 5, 6, 6, 6, 7, 7, 7, 7, 8, 9, 10]) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
assert unique(
    [1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]) == [1, 3]
assert unique([1, 1, 2, 2, 2, 3, 3, 3]) == [1, 2, 3]
assert unique(unique([1, 2, 3, 4, 1, 2, 3, 4])) == [1, 2, 3, 4]
assert unique([1, 2]) == [1, 2]
assert unique([1, 1, 2, 1]) == [1, 2]
assert unique(unique([1, 2, 3, 3, 4, 4, 5, 5, 6])) == [1, 2, 3, 4, 5, 6]
assert unique([1, 2, 3, 1, 2, 3]) == [1, 2, 3]
assert unique(
    [1, 2, 3, 2, 3, 4, 2, 3, 4, 5]) == [1, 2, 3, 4, 5]
assert unique(
    ['a', 'b', 'c', 'd', 'e', 'f', 'g']) == ['a', 'b', 'c', 'd', 'e', 'f', 'g']
assert unique(
    ['a', 'a', 'b', 'b', 'c', 'd']) == ['a', 'b', 'c', 'd']
assert unique(unique([1, 1, 1, 1, 1, 1, 1, 1])) == [1]
assert unique(['cat', 'dog', 'cat', 'goldfish', 'dog']) == ['cat', 'dog', 'goldfish']
assert unique(unique(["hi", "hi", "bye"])) == ["bye", "hi"]
assert unique(["A", "A", "A", "A"]) == ["A"]
assert unique([1, 2, 3, 1, 2, 3, 1, 2, 3]) == [1, 2, 3]
assert unique([1, 2, 3, 1, 2, 3, 1, 2, 3, 1, 2, 3]) == [1, 2, 3]
assert unique(["a", "b", "c"]) == ["a", "b", "c"]
assert unique(["  A  ", "  B  ", "  C  "]) == ["  A  ", "  B  ", "  C  "]
assert unique(['a', 'a', 'b', 'b', 'c', 'c', 'c']) == ['a', 'b', 'c']
assert unique([1, 2, 2, 3, 3, 3, 4, 5]) == [1, 2, 3, 4, 5]
assert unique([2.7, 2.7]) == [2.7]
assert unique(['a', 'a', 'b', 'b', 'c', 'c']) == ['a', 'b', 'c']
assert unique([1, 2, 1, 3, 1, 2, 3]) == [1, 2, 3]
assert unique([1, 2, 3]) == [1, 2, 3]
assert unique(
    ["B", "B", "C", "D", "B", "A", "C", "B"]) == ["A", "B", "C", "D"]
assert unique(['A', 'A', 'B', 'C']) == ['A', 'B', 'C']
assert unique(['1', '2', '3', '1', '2', '3', '1', '2', '3']) == ['1', '2', '3']
assert unique([4, 4, 4, 4, 4, 4]) == [4]
assert unique([1, 2, 3, 4, 5, 5, 6, 7, 7, 7, 8, 8, 9, 9, 10]) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
assert unique(unique([1])) == [1]
assert unique([1, 1, 2, 3, 3, 3]) == [1, 2, 3]
assert unique(
    ['a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'b']) == ['a', 'b']
assert unique(["hi", "hi", "bye"]) == ["bye", "hi"]
assert unique(["A  ", "B  ", "C  "]) == ["A  ", "B  ", "C  "]
assert unique([3, 3, 3, 3, 3, 3]) == [3]
assert unique([1, 1, 1, 1]) == [1]
assert unique([1, 2, 3, 4, 1, 2, 3, 4]) == [1, 2, 3, 4]
assert unique(
    [1, 1, 2, 3, 4, 4, 5, 6, 7, 8, 8, 9, 10, 11, 11]) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
assert unique(unique([1, 1, 2, 3, 3, 4, 5])) == [1, 2, 3, 4, 5]
assert unique(["A", "B", "C"]) == ["A", "B", "C"]
