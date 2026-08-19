def call(callable_, *args, **kwargs):
    """:yaql:call

    Evaluates function with specified args and kwargs and returns the
    result.
    This function is used to transform expressions like '$foo(args, kwargs)'
    to '#call($foo, args, kwargs)'.
    Note that to use this functionality 'delegate' mode has to be enabled.

    :signature: call(callable, args, kwargs)
    :arg callable: callable function
    :argType callable: python type
    :arg args: sequence of items to be used for calling
    :argType args: sequence
    :arg kwargs: dictionary with kwargs to be used for calling
    :argType kwargs: mapping
    :returnType: any (callable return type)
    """
    return callable_(*args, **kwargs)

assert call(lambda *args: args, "a", "b", "c") == ("a", "b", "c")
assert call(len, (1, 2, 3, 4, 5)) == 5
assert call(lambda x, y: x + y, 4, 4.0) == 8.0
assert call(lambda x: x, 4j) == 4j
assert call(lambda x, y: x + y, [], []) == []
assert call(len, (1, 2)) == 2
assert call(int, 10) == 10
assert call(lambda x: x, [1, 2]) == [1, 2]
assert call(
    lambda x: 2 * x,  # noqa
    4,
) == 8
assert call(lambda *x: x, 1, 2) == (1, 2)
assert call(
    lambda x, y, z: x * y * z,  # noqa
    2,
    3,
    5,
) == 30
assert call(lambda: "foo") == "foo"
assert call(sum, (1, 2, 3, 4, 5), 100) == 115
assert call(str, 1) == "1"
assert call(int, "10") == 10
assert call(lambda x, y: x + y, 4, 5) == 9
assert call(lambda: 5) == 5
assert call(lambda: None) == None
assert call(lambda x, y, z: x + y + z, 4, 4, 4.0) == 12
assert call(lambda x, y=2: x + y, 1) == 3
assert call(lambda: {}) == {}
assert call(lambda x, y: x + y, 1.0, 2.0) == 3.0
assert call(abs, -1.1) == 1.1
assert call(lambda a, b, c=1: a + b + c, 4, 5) == 10
assert call(lambda x: x, 4) == 4
assert call(lambda x, y, z: x + y + z, "", "", "") == ""
assert call(lambda *args: len(args), 1, 2, 3) == 3
assert call(lambda x, y: x + y, 4.0, 4) == 8.0
assert call(len, [1, 2]) == 2
assert call(lambda: "Hello, World!") == "Hello, World!"
assert call(lambda x: x + 1, 3) == 4
assert call(lambda x, y=2: x + y, 1, 2) == 3
assert call(lambda x, y, *args: x + y + sum(args), 1, 2, 3, 4, 5) == 15
assert call(lambda x: x ** 2, 3) == 9
assert call(lambda x, y: x + y, 4.0, 4j) == 4j + 4.0
assert call(
    lambda x, y, z, *args: (x, y, z, args),  # noqa
    1,
    2,
    3,
    4,
    5,
) == (1, 2, 3, (4, 5))
assert call(lambda x, y: x, 1, 2) == 1
assert call(sum, [1, 2, 3, 4, 5]) == 15
assert call(lambda a: a, 1) == 1
assert call(lambda: "") == ""
assert call(lambda a, b, c: a + b + c, 1, 2, 3) == 6
assert call(lambda *args: len(args), 1) == 1
assert call(lambda x, y, z: x + y + z, 1, 2, 3) == 6
assert call(lambda *args, **kwargs: len(args) + len(kwargs)) == 0
assert call(lambda x, y, z: x + y + z, 1.0, 2.0, 3.0) == 6.0
assert call(lambda *args, **kwargs: args, 1, 2) == (1, 2)
assert call(lambda *args: len(args)) == 0
assert call(lambda **kwargs: len(kwargs)) == 0
assert call(set, [1, 2, 3]) == {1, 2, 3}
assert call(lambda x: x, 1.0) == 1.0
assert call(lambda x, y=4: 5, 4) == 5
assert call(lambda a, b, c, d: a + b + c + d, 1, 2, 3, 4) == 10
assert call(lambda x: 5, 4) == 5
assert call(max, {1, 2, 3, 4, 5}) == 5
assert call(lambda x, y: x + y, "", "") == ""
assert call(lambda x, y: x + y, 4j, 4.0) == 4.0 + 4j
assert call(max, (1, 2, 3, 4, 5)) == 5
assert call(abs, -1) == 1
assert call(lambda x, y: x + y, 4j, 4j) == 4j + 4j
assert call(lambda a=1, b=2: a + b, 4) == 6
assert call(int) == 0
assert call(lambda: 1 + 2) == 3
assert call(lambda x, y, z=10: x + y + z, 1, 2) == 13
assert call(lambda x, y: x + y, 4.0, 4.0) == 8.0
assert call(lambda a, b=2, c=3: a + b + c, 1) == 6
assert call(lambda: 1) == 1
assert call(set, {1, 2, 3}) == {1, 2, 3}
assert call(list, {1, 2, 3}) == [1, 2, 3]
assert call(lambda *args: args) == ()
assert call(lambda a=1, b=2: a + b, 4, 5) == 9
assert call(
    lambda x, y, *args: (x, y, args),  # noqa
    1,
    2,
    3,
    4,
) == (1, 2, (3, 4))
assert call(lambda x, y: 5, 4, 3) == 5
assert call(sum, [1, 2, 3, 4, 5], 100) == 115
assert call(min, 3, 2) == 2
assert call(abs, 1) == 1
assert call(sum, {1, 2, 3, 4, 5}) == 15
assert call(lambda x, y, z=2: x + y + z, 1, 2, 3) == 6
assert call(lambda a, b: a + b, 2, 3) == 5
assert call(lambda *args: sum(args), 1, 2, 3) == 6
assert call(abs, -4.0) == 4.0
assert call(lambda x: x, "") == ""
assert call(
    lambda: 2,  # noqa
) == 2
assert call(lambda x: x, []) == []
assert call(lambda *args: args, "a", "b") == ("a", "b")
assert call(
    lambda *args: args,  # noqa
) == ()
assert call(lambda a, b, *c: a + b + sum(c), 1, 2) == 3
assert call(list, {1: 'a', 2: 'b', 3: 'c'}) == [1, 2, 3]
assert call(lambda x, y, z: x + y + z, 4, 4, 4) == 12
assert call(
    lambda *args: args,  # noqa
    1,
    2,
    3,
) == (1, 2, 3)
assert call(lambda a=1, b=2, c=3: a + b + c) == 6
assert call(lambda x: x, 10) == 10
assert call(lambda x, y, z=2: x + y + z, 1, 2) == 5
assert call(lambda x, *args: x + sum(args), 1, 2, 3, 4) == 10
assert call(lambda x, y, z: (x, y, z), 1, 2, 3) == (1, 2, 3)
assert call(lambda x, y, *args: x + y + sum(args), 1, 2, 3) == 6
assert call(sum, {1, 2, 3, 4, 5}, 100) == 115
assert call(lambda **kwargs: kwargs) == {}
assert call(lambda x, y, z=3: (x, y, z), 1, 2, 4) == (1, 2, 4)
assert call(lambda x, y, *args: x + y + sum(args), 1, 2, 3, 4) == 10
assert call(lambda x, y, z=1: x + y + z, 1, 2, 3) == 6
assert call(lambda *args: args, "a") == ("a",)
assert call(list, {'a': 1, 'b': 2, 'c': 3}) == ['a', 'b', 'c']
assert call(lambda x: x, {}) == {}
assert call(len, ["a", "b", "c"]) == 3
assert call(min, 2, 3) == 2
assert call(sum, (1, 2, 3, 4, 5)) == 15
assert call(lambda a=1, b=2, c=3: a + b + c, 1, 2) == 6
assert call(lambda x: x, {"x": 1, "y": 2}) == {"x": 1, "y": 2}
assert call(lambda x, y, z=3: (x, y, z), 1, 2) == (1, 2, 3)
assert call(lambda: []) == []
assert call(lambda x, y: x + y, 4, 4) == 8
assert call(list, [1, 2, 3]) == [1, 2, 3]
assert call(int, "1") == 1
assert call(lambda x, **kwargs: x + sum(kwargs.values()), 1) == 1
assert call(lambda x, y, z=1: x + y + z, 1, 2) == 4
assert call(lambda: {"foo": 1, "bar": 2}) == {"foo": 1, "bar": 2}
assert call(lambda: 10) == 10
assert call(len, []) == 0
assert call(set, (1, 2, 3)) == {1, 2, 3}
assert call(abs, -4) == 4
assert call(lambda a, b=1: a + b, 4, 5) == 9
assert call(lambda x: x, {"x": 1}) == {"x": 1}
assert call(lambda x: x, {"y": 2, "x": 1}) == {"y": 2, "x": 1}
assert call(lambda x, y, z, *args: x + y + z + sum(args), 1, 2, 3, 4) == 10
assert call(lambda x, y: x + y, 2, 3) == 5
assert call(lambda x, y: x + y, 1, 2) == 3
assert call(max, [1, 2, 3, 4, 5]) == 5
assert call(abs, 0) == 0
assert call(list, (1, 2, 3)) == [1, 2, 3]
assert call(lambda x, y, z, a: x + y + z + a, 1, 2, 3, 4) == 10
assert call(lambda x, *args: x + sum(args), 1, 2) == 3
assert call(lambda x, *args: x + sum(args), 1, 2, 3, 4, 5) == 15
assert call(lambda a, b: a + b, 1, 2) == 3
assert call(abs, 1.1) == 1.1
assert call(lambda x: x + 1, 1) == 2
assert call(lambda x: x, 4.0) == 4.0
assert call(len, {1: 2}) == 1
assert call(lambda x: x, 1) == 1
assert call(lambda x, y, z: x + y + z, [], [], []) == []
assert call(lambda a, b=1: a + b, 4) == 5
