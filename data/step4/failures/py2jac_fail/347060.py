def hashable(obj):
    """Convert `obj` into a hashable object."""
    if isinstance(obj, list):
        # Convert a list to a tuple (hashable)
        return tuple(obj)
    elif isinstance(obj, dict):
        # Convert a dict to a frozenset of items (hashable)
        return frozenset(obj.items())
    return obj

assert hashable((3, 4)) == (3, 4)
assert hashable(list()) == tuple()
assert hashable([]) == ()
assert hashable(tuple()) == ()
assert hashable({"a": 3}) == frozenset({"a": 3}.items())
assert hashable({1: "a", 2: "b", 3: "c"}) == frozenset([(1, "a"), (2, "b"), (3, "c")])
assert hashable('hello') == 'hello'
assert hashable({'a': 'b'}) == frozenset([('a', 'b')])
assert hashable({"a": 1, "b": 2}.items()) == frozenset({"a": 1, "b": 2}.items())
assert hashable({1: 2, 3: 4}) == frozenset([(1, 2), (3, 4)])
assert hashable(b"abc") == b"abc"
assert hashable(b"42") == b"42"
assert hashable(set()) == frozenset()
assert hashable({"one": 1}) == frozenset([("one", 1)])
assert hashable([1, 2, 3.0]) == (1, 2, 3.0)
assert hashable((1,)) == (1,)
assert hashable(range(3)) == range(3)
assert hashable(([],)) == ([],)
assert hashable({'foo': 1}) == frozenset([('foo', 1)])
assert hashable(0) == 0
assert hashable('hello') == 'hello'
assert hashable(bytearray("42", "ascii")) == bytearray("42", "ascii")
assert hashable((1, 2, 3, (1, 2, 3), {"a": 1})) == (1, 2, 3, (1, 2, 3), {"a": 1})
assert hashable(['1', '2', '3']) == ('1', '2', '3')
assert hashable({1: "a", 2: "b", 3: "c", 4: "a"}) == frozenset([(1, "a"), (2, "b"), (3, "c"), (4, "a")])
assert hashable([1, 2, 'hello']) == (1, 2, 'hello')
assert hashable(True) == True
assert hashable(frozenset([1,2,3])) == frozenset([1,2,3])
assert hashable([3, 4]) == (3, 4)
assert hashable(frozenset([1, 2, 3])) == frozenset([1, 2, 3])
assert hashable(123) == 123
assert hashable(type) == type
assert hashable(set({"a", "b"})) == frozenset({"a", "b"})
assert hashable(3) == 3
assert hashable("42") == "42"
assert hashable(1.0) == 1.0
assert hashable({}) == frozenset()
assert hashable([]) == tuple([])
assert hashable((3,)) == (3,)
assert hashable([1, 2, 3, 4]) == (1, 2, 3, 4)
assert hashable({"hello": 1, "world": 2, "foo": 3}) == frozenset([("hello", 1), ("world", 2), ("foo", 3)])
assert hashable("42") == "42"
assert hashable(0.0) == 0.0
assert hashable(bytearray(b"abc")) == bytearray(b"abc")
assert hashable({'a': 1}) == frozenset([('a', 1)])
assert hashable({'a': 0, 'b': 0}) == frozenset([('b', 0), ('a', 0)])
assert hashable({3:4}) == frozenset({(3, 4)})
assert hashable({"1": 1, "2": 2}) == frozenset([("1", 1), ("2", 2)])
assert hashable(dict()) == frozenset()
assert hashable((1, (2, (3, ())), {4: (5, {6: (7,)})})) == \
    (1, (2, (3, ())), {4: (5, {6: (7,)})})
assert hashable(1.2) == 1.2
assert hashable(complex(1, 0)) == complex(1, 0)
assert hashable({"a": 1, "b": 2}) == frozenset([("a", 1), ("b", 2)])
assert hashable({"hello": 1}) == frozenset([("hello", 1)])
assert hashable(frozenset([1])) == frozenset([1])
assert hashable(42.0) == 42.0
assert hashable('a') == 'a'
assert hashable(42) == 42
assert hashable("hello world") == "hello world"
assert hashable("foo") == "foo"
assert hashable(False) == False
assert hashable(hashable) == hashable
assert hashable(set()) == set()
assert hashable(b"hello") == b"hello"
assert hashable("abc") == "abc"
assert hashable(3.14) == 3.14
assert hashable(1.) == 1.
assert hashable([1.0]) == (1.0,)
assert hashable([1, 2, 3]) == (1, 2, 3)
assert hashable(['hello']) == ('hello',)
assert hashable(tuple([1, 2])) == tuple([1, 2])
assert hashable([1, 2]) == (1, 2)
assert hashable({'a': 1, 'b': 2}) == frozenset({'a': 1, 'b': 2}.items())
assert hashable(None) == None
assert hashable('foo') == 'foo'
assert hashable({"a": 1, "b": 2}) == frozenset({"a": 1, "b": 2}.items())
assert hashable({1: 2}) == frozenset([(1, 2)])
assert hashable([1, 2, b'hello']) == (1, 2, b'hello')
assert hashable(list()) == ()
assert hashable({'a': 0, 'b': 0}) == frozenset([('a', 0), ('b', 0)])
assert hashable("one") == "one"
assert hashable({"a": 42, "b": 100}) == frozenset({("a", 42), ("b", 100)})
assert hashable({'b': 2, 'a': 1}) == frozenset([('a', 1), ('b', 2)])
assert hashable(['hello']) == ('hello',)
assert hashable(tuple()) == tuple()
assert hashable(set([1, 2, 3])) == set([1, 2, 3])
assert hashable({"hello", "world", "foo"}) == frozenset(["hello", "world", "foo"])
assert hashable({1:2,3:4}) == frozenset([(1,2),(3,4)])
assert hashable(tuple("abc")) == tuple("abc")
assert hashable((1, 2, 3)) == (1, 2, 3)
assert hashable(10) == 10
assert hashable(12345) == 12345
assert hashable((1, 2, 3, (1, 2, 3))) == (1, 2, 3, (1, 2, 3))
assert hashable(frozenset()) == frozenset()
assert hashable(frozenset({"a", "b"})) == frozenset({"a", "b"})
assert hashable({'foo': 1, 'bar': 2}) == frozenset([('bar', 2), ('foo', 1)])
assert hashable(set([1])) == set([1])
assert hashable(["hello", "world"]) == ("hello", "world")
assert hashable(complex(0, 1)) == complex(0, 1)
assert hashable({"hello": 1, "world": 2}) == frozenset([("hello", 1), ("world", 2)])
assert hashable([3]) == (3,)
assert hashable([b'hello']) == (b'hello',)
assert hashable([1,2,3]) == (1,2,3)
assert hashable(tuple({1, 2, 3})) == tuple({1, 2, 3})
assert hashable(["a", "b"]) == ("a", "b")
assert hashable(()) == ()
assert hashable("abc") == "abc"
assert hashable("hi") == "hi"
assert hashable(b'bar') == b'bar'
assert hashable((1, 2)) == (1, 2)
assert hashable("hello") == "hello"
assert hashable(1+2j) == 1+2j
assert hashable([1]) == (1,)
assert hashable({1,2,3}) == frozenset([1,2,3])
assert hashable([1, 2, 'hello']) == (1, 2, 'hello')
assert hashable(123.456) == 123.456
assert hashable({3:3}) == frozenset({(3, 3)})
assert hashable(1) == 1
assert hashable(b'hello') == b'hello'
assert hashable({1: 2, 3: 4}) == frozenset({(1, 2), (3, 4)})
assert hashable({'a': 1, 'b': 2}) == frozenset([('a', 1), ('b', 2)])
assert hashable({"a": 42}) == frozenset({("a", 42)})
assert hashable({"a": 1}) == frozenset([("a", 1)])
assert hashable("string") == "string"
assert hashable((1,2,3)) == (1,2,3)
assert hashable(3.14j) == 3.14j
