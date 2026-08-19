def is_iterable(obj):
    """ Check for the `__iter__` attribute so that this can cover types that 
        don't have to be known by this module, such as NumPy arrays. """
    return hasattr(obj, '__iter__') and not isinstance(obj, str)

assert is_iterable("5") == False
assert is_iterable("") == False
assert is_iterable(bytearray(b'World!')) == True
assert is_iterable(12) == False
assert is_iterable('	') == False
assert is_iterable(bytearray()) == True
assert is_iterable(range(0, 10)) == True
assert is_iterable((1, 2, 3)) == True
assert is_iterable(1.0) == False
assert is_iterable({'1': 'a', '2': 'b'}) == True
assert is_iterable([1]) == True
assert is_iterable(iter(range(0, 10))) == True
assert is_iterable({1:'a', 2:'b'}) == True
assert is_iterable(' ') == False
assert is_iterable(list()) == True
assert is_iterable(tuple((i for i in range(5)))) == True
assert is_iterable(iter("abc")) == True
assert is_iterable(b'Hello, World!') == True
assert is_iterable(4) == False
assert is_iterable(set()) == True
assert is_iterable(bytearray(b' ')) == True
assert is_iterable(iter([1, 2, 3])) == True
assert is_iterable([[1, 2], [3, 4], [5, 6]]) == True
assert is_iterable('abc') == False
assert is_iterable("test") == False
assert is_iterable({"a": 1, "b": 2, "c": 3}) == True
assert is_iterable([]) == True
assert is_iterable(1.1) == False
assert is_iterable((1,2,3)) == True
assert is_iterable(b'1') == True
assert is_iterable(False) == False
assert is_iterable('s') == False
assert is_iterable(5.0) == False
assert is_iterable(bool) == False
assert is_iterable(range(0)) == True
assert is_iterable('Hello') == False
assert is_iterable("asdf") == False
assert is_iterable(b'') == True
assert is_iterable([1, 2, 3, 4, 5]) == True
assert is_iterable(object()) == False
assert is_iterable(object) == False
assert is_iterable(dict()) == True
assert is_iterable(lambda x: x) == False
assert is_iterable(None) == False
assert is_iterable({1:2}) == True
assert is_iterable(b'		') == True
assert is_iterable(1+2j) == False
assert is_iterable(frozenset()) == True
assert is_iterable(10) == False
assert is_iterable([1, "asdf"]) == True
assert is_iterable(0) == False
assert is_iterable(bytearray(b'	')) == True
assert is_iterable({1,2,3}) == True
assert is_iterable(bytearray(b'Hello')) == True
assert is_iterable(2) == False
assert is_iterable('1.0') == False
assert is_iterable('Hello, World!') == False
assert is_iterable([1, 2, 3]) == True
assert is_iterable(3) == False
assert is_iterable((x for x in range(0, 10))) == True
assert is_iterable(set([1, 2, 3])) == True
assert is_iterable(b' ') == True
assert is_iterable(0.0) == False
assert is_iterable(Ellipsis) == False
assert is_iterable(b'1.0') == True
assert is_iterable([1, 2, [3, 4, 5]]) == True
assert is_iterable((x for x in range(10))) == True
assert is_iterable(is_iterable) == False
assert is_iterable(iter([])) == True
assert is_iterable(1.5) == False
assert is_iterable(bytearray(b'1.0')) == True
assert is_iterable("1") == False
assert is_iterable(iter("")) == True
assert is_iterable(tuple()) == True
assert is_iterable(1) == False
assert is_iterable('1') == False
assert is_iterable(range(0, 1)) == True
assert is_iterable(float) == False
assert is_iterable('foo') == False
assert is_iterable("string") == False
assert is_iterable('		') == False
assert is_iterable('World!') == False
assert is_iterable(bytearray(b'1')) == True
assert is_iterable({"a": 1, "b": 2}) == True
assert is_iterable(123) == False
assert is_iterable({"a": 1}) == True
assert is_iterable({}) == True
assert is_iterable('a') == False
assert is_iterable([1,2,3]) == True
assert is_iterable(1.) == False
assert is_iterable(range(1, 4)) == True
assert is_iterable(range(10)) == True
assert is_iterable({1: "asdf"}) == True
assert is_iterable(range(5)) == True
assert is_iterable([1, 2]) == True
assert is_iterable(()) == True
assert is_iterable(range(4)) == True
assert is_iterable(b'Hello') == True
assert is_iterable(range(1)) == True
assert is_iterable("hello") == False
assert is_iterable(b'World!') == True
assert is_iterable(1.2) == False
assert is_iterable({'1': 1, '2': 2, '3': 3}) == True
assert is_iterable(3.14) == False
assert is_iterable('') == False
assert is_iterable(b'	') == True
assert is_iterable('hello') == False
assert is_iterable({1, 2, 3}) == True
assert is_iterable((1, "asdf")) == True
assert is_iterable([1, 2, 3, [4, 5, 6]]) == True
assert is_iterable(iter(range(10))) == True
assert is_iterable(True) == False
assert is_iterable(42) == False
assert is_iterable((1, 2)) == True
assert is_iterable(bytearray(b'')) == True
assert is_iterable('foo') == False
