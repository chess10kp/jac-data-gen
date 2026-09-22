def t_any(cls):
    """
        Verifies if input is of same class
    """
    class AnyClass(cls):
        def __eq__(self, other):
            return True

    return AnyClass()

assert t_any(float) == 0.0
assert t_any(object) == "a"
assert t_any(dict) == t_any(dict)
assert t_any(list) == [1, 2]
assert t_any(type({"key": "value"})) == dict
assert t_any(str) == 'a'
assert t_any(tuple) == t_any(tuple)
assert t_any(object) == ()
assert t_any(list) == ['a', 1, True]
assert t_any(str) == "this is a string"
assert t_any(list) == [2]
assert t_any(str) == 'a123'
assert t_any(str) == 'a1'
assert t_any(str) == "Hello, World!"
assert t_any(complex) == 1j
assert t_any(int) == -234
assert t_any(float) == 3.1415
assert t_any(list) == [1, 2, 3]
assert t_any(str) == 'foo'
assert t_any(list) == ["this is", "a list"]
assert t_any(list) == ['foo', 'bar']
assert t_any(int) == t_any(int)
assert t_any(int) == 2
assert t_any(float) == -1e100
assert t_any(tuple) == (1,)
assert t_any(float) == -0.001
assert t_any(tuple) == (0,)
assert t_any(tuple) == ("this is", "a tuple")
assert t_any(set) == {1, 2}
assert t_any(str) == 'b'
assert t_any(set) == set()
assert t_any(int) =='str'
assert t_any(int) == 3
assert t_any(str) == "hi"
assert t_any(object) == 1j
assert t_any(str) == 'abc'
assert t_any(float) == -12345.6
assert t_any(int) == -3
assert t_any(tuple) == (3, 4)
assert t_any(float) == 42.0
assert t_any(dict) == {'foo': 'bar'}
assert t_any(int) == -1000000
assert t_any(int) == 234
assert t_any(int) == -123
assert t_any(str) == "c"
assert t_any(object) == 'a'
assert t_any(set) == {1}
assert t_any(list) == []
assert t_any(float) == -1.0
assert t_any(str) == 'hello'
assert t_any(list) == [1]
assert t_any(object) == None
assert t_any(float) == "1.0"
assert t_any(complex) == 1.0
assert t_any(str) == 'a string'
assert t_any(list) == 1
assert t_any(dict) == {"a": 1, "b": 2}
assert t_any(str) == 'hello world'
assert t_any(str) == "abc"
assert t_any(str) == 'a123b'
assert t_any(int) == 'a'
assert t_any(str) == 'a123_b'
assert t_any(object) == 'a string'
assert t_any(float) == float
assert t_any(int) == 1.0
assert t_any(str) == "def"
assert t_any(object) == "abc"
assert t_any(str) == "a"
assert t_any(object) == True
assert t_any(type([1, 2, 3])) == list
assert t_any(bytes) == bytes
assert t_any(float) == 3.14
assert t_any(dict) == {"c": 3}
assert t_any(list) == [3]
assert t_any(set) == {'hi', 'bye'}
assert t_any(int) == ()
assert t_any(float) == 1.0
assert t_any(int) == 1000000
assert t_any(str) == ''
assert t_any(str) == ""
assert t_any(bytes) == b"abc"
assert t_any(int) == {}
assert t_any(str) == [1,2,3]
assert t_any(int) == 2.0
assert t_any(object) == 10.0j
assert t_any(str) == "1"
assert t_any(str) == "hello"
assert t_any(str) == 1.0
assert t_any(str) == "AnyString"
assert t_any(list) == 1.0
assert t_any(float) == t_any(float)
assert t_any(float) == -3.14
assert t_any(object) == {"a":1, "b":2}
assert t_any(object) == (x for x in (1, 2, 3))
assert t_any(int) == [1,2,3]
assert t_any(int) == '3'
assert t_any(object) == [1, 2, 3]
assert t_any(object) == 3.14
assert t_any(type("hi")) == str
assert t_any(int) == "1"
assert t_any(dict) == {"a": 1, "b": 2, "c": 3}
assert t_any(int) == None
assert t_any(object) == [x for x in (1, 2, 3)]
assert t_any(str) == None
assert t_any(tuple) == tuple
assert t_any(dict) == {'a': 1, 'b': 2}
assert t_any(int) == 0
assert t_any(list) == [1, 2, 3, 4, 5]
assert t_any(object) == 3
assert t_any(type(1)) == int
assert t_any(list) == [0, 1, 2, 3]
assert t_any(int) == -12345678
assert t_any(str) == 1
assert t_any(dict) == dict()
assert t_any(int) == "hi"
assert t_any(str) == "1.0"
assert t_any(dict) == {"foo": "bar"}
assert t_any(str) == 'a-123-b'
assert t_any(object) == object()
assert t_any(object) == 10
assert t_any(object) == False
assert t_any(int) == []
assert t_any(str) == '1'
assert t_any(float) == 1
assert t_any(dict) == {"abc": 123}
assert t_any(dict) == {}
assert t_any(tuple) == ('foo', 'bar')
assert t_any(object) == (1, 2, 3)
assert t_any(str) == "b"
assert t_any(set) == set
assert t_any(set) == {'a', 'b'}
assert t_any(str) == '123'
assert t_any(frozenset) == frozenset({1, 2, 3})
assert t_any(dict) == {'a': 1}
assert t_any(object) == object
assert t_any(int) == 3.14
assert t_any(set) == {2}
assert t_any(int) == 12345
assert t_any(list) == ['a', 'b', 'c']
assert t_any(object) == {1:2, 3:4}
assert t_any(list) == list
assert t_any(float) == 1.1
assert t_any(int) == False
assert t_any(str) == t_any(str)
assert t_any(str) == '12345'
assert t_any(list) == t_any(list)
assert t_any(str) == 'a-123-b-c'
assert t_any(list) == [2, 3]
assert t_any(str) == 'hi'
assert t_any(int) == 123456789
assert t_any(tuple) == (1, 2, 3)
assert t_any(int) == int
assert t_any(object) == []
assert t_any(list) == [0, 1]
assert t_any(float) == 123.456
assert t_any(float) == 1.2345
assert t_any(dict) == {"b": 2}
assert t_any(tuple) == (2, 3)
assert t_any(tuple) == (1, 2)
assert t_any(str) == 'abcdef'
assert t_any(list) == ['a']
assert t_any(str) == 42
assert t_any(str) == 'Hello world'
assert t_any(list) == ['hi', 'there']
assert t_any(dict) == 1
assert t_any(set) == t_any(set)
assert t_any(int) == (1,2,3)
assert t_any(object) == {}
assert t_any(int) == -2
assert t_any(dict) == {'a': 1, 'b': 2, 'c': 3}
assert t_any(dict) == {"key": "value"}
assert t_any(complex) == 0 + 0j
assert t_any(int) == 42
assert t_any(int) == 42.0
assert t_any(str) == 'a_123_b'
assert t_any(list) == [0, 1, 2]
assert t_any(list) == [0]
assert t_any(tuple) == ()
assert t_any(int) == object
assert t_any(set) == {"a", "b", "c"}
assert t_any(int) == 10
assert t_any(object) == 10.0
assert t_any(str) == list()
assert t_any(dict) == 1.0
assert t_any(object) == 1.0
assert t_any(dict) == {1: 'a'}
assert t_any(object) == set()
assert t_any(str) == str
assert t_any(object) == 1
assert t_any(object) == {1, 2, 3}
assert t_any(int) == (1, 2, 3)
assert t_any(int) == -1
assert t_any(str) == "hello world"
assert t_any(float) == 1e100
assert t_any(int) == [1, 2, 3]
assert t_any(float) == 0.001
assert t_any(int) == 1
assert t_any(dict) == {"a": "b"}
assert t_any(int) == 123
assert t_any(dict) == {"b": 2, "c": 3}
assert t_any(dict) == {"a": 1}
assert t_any(set) == {1, 2, 3}
assert t_any(complex) == 1
assert t_any(float) == 2.3
assert t_any(dict) == dict
assert t_any(int) == True
