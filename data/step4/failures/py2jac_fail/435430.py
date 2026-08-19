def tap(fun, value):
    """
    A function that takes a function and a value, applies the function
    to the value and returns the value.

    Complexity: O(k) where k is the complexity of the given function
    params:
        fun: the function
        value: the value
    returns: the value
    """
    fun(value)
    return value

assert tap(lambda x: print('x =', x), 2) == 2
assert tap(lambda x: print(x), (1, 2, 3)) == (1, 2, 3)
assert tap(lambda x: None, 1) == 1
assert tap(lambda x: print(x) if x > 0 else None, 3) == 3
assert tap(lambda x: print("x = {}".format(x)), "str") == "str"
assert tap(lambda value: print(value), 0) == 0
assert tap(lambda x: x + 1, (lambda x: x + 1)(10)) == 11
assert tap(print, "hello") == "hello"
assert tap(print, 2) == 2
assert tap(lambda x: print(x), 1) == 1
assert tap(lambda x: print(x), 2) == 2
assert tap(lambda x: x ** 2, 2) == 2
assert tap(print, 12) == 12
assert tap(lambda x: print(x), 10) == 10
assert tap(print, "I'm a value") == "I'm a value"
assert tap(lambda x: x ** 2, 4) == 4
assert tap(lambda x: print("x = {}".format(x)), [1, 2, 3]) == [1, 2, 3]
assert tap(lambda x: x + 1, 3) == 3
assert tap(lambda x: None, 10) == 10
assert tap(lambda x: print(x), "world") == "world"
assert tap(lambda x: print(x), 3) == 3
assert tap(lambda x: print(x), '1') == '1'
assert tap(lambda x: print(x), 'abc') == 'abc'
assert tap(print, "test") == "test"
assert tap(lambda x: print(x), {'a': 1}) == {'a': 1}
assert tap(print, 'abc') == 'abc'
assert tap(print, 1) == 1
assert tap(print, [1,2,3]) == [1,2,3]
assert tap(lambda x: print(x + 1), 6) == 6
assert tap(print, 2 + 3) == 5
assert tap(print, 10) == 10
assert tap(lambda x: print(x), 1.0) == 1.0
assert tap(lambda x: x, 5) == 5
assert tap(lambda x: print(x * x), 3) == 3
assert tap(lambda x: None, 5) == 5
assert tap(print, "Hello, World") == "Hello, World"
assert tap(lambda x: print("x = {}".format(x)), 0) == 0
assert tap(lambda x: print("x = {}".format(x)), (1, 2, 3)) == (1, 2, 3)
assert tap(lambda x: print(x), [1, 2, 3]) == [1, 2, 3]
assert tap(print, 100) == 100
assert tap(lambda x: print(x), 5) == 5
assert tap(lambda x: x + 1, 2) == 2
assert tap(print, {"foo": "bar"}) == {"foo": "bar"}
assert tap(print, 2 ** 3) == 8
assert tap(lambda x: x, "test") == "test"
assert tap(print, "Hello World") == "Hello World"
assert tap(print, "hi") == "hi"
assert tap(lambda x: print(x), "hello") == "hello"
assert tap(lambda x: print(x), True) == True
assert tap(lambda x: print(f"x = {x}"), 42) == 42
assert tap(lambda x: print(x), 100) == 100
assert tap(lambda x: print(x) if x > 0 else None, -2) == -2
assert tap((lambda x: x + 1), 10) == 10
assert tap(lambda x: print(x + 1), 5) == 5
