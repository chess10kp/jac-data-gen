def _PruneMessage(obj):
  """Remove any common structure in the message object before printing."""
  if isinstance(obj, list) and len(obj) == 1:
    return _PruneMessage(obj[0])
  elif isinstance(obj, dict) and len(obj) == 1:
    for v in obj.values():
      return _PruneMessage(v)
  else:
    return obj

assert _PruneMessage({'a': 1, 'b': 2}) == {'a': 1, 'b': 2}
assert _PruneMessage([[True]]) == True
assert _PruneMessage({'a': None}) == None
assert _PruneMessage([1, {"x": [2, {"y": 3}]}]) == [1, {"x": [2, {"y": 3}]}]
assert _PruneMessage([None]) == None
assert _PruneMessage({"foo": [1, 2, 3]}) == [1, 2, 3]
assert _PruneMessage("foo") == "foo"
assert _PruneMessage(1.0) == 1.0
assert _PruneMessage([1.0, 2.0]) == [1.0, 2.0]
assert _PruneMessage([False, False]) == [False, False]
assert _PruneMessage([1, 1]) == [1, 1]
assert _PruneMessage(3) == 3
assert _PruneMessage({'a': 1}) == 1
assert _PruneMessage("foo") == "foo"
assert _PruneMessage(1.0+2.0j) == (1.0+2.0j)
assert _PruneMessage({'a': 1, 'b': {'c': 2}}) == {'a': 1, 'b': {'c': 2}}
assert _PruneMessage(["hello"]) == "hello"
assert _PruneMessage([3]) == 3
assert _PruneMessage(bytearray()) == bytearray()
assert _PruneMessage({}) == {}
assert _PruneMessage(
    [{'a': 1, 'b': 2}, {'a': 3, 'b': 4}]) == [{'a': 1, 'b': 2}, {'a': 3, 'b': 4}]
assert _PruneMessage({"foo": [[1, 2, 3], [4, 5, 6]]}) == [[1, 2, 3], [4, 5, 6]]
assert _PruneMessage([None, 1, None]) == [None, 1, None]
assert _PruneMessage([1.2, 2.4]) == [1.2, 2.4]
assert _PruneMessage(float('inf')) == float('inf')
assert _PruneMessage(0) == 0
assert _PruneMessage(b"foo") == b"foo"
assert _PruneMessage({1: 2, 3: 4}) == {1: 2, 3: 4}
assert _PruneMessage([["foo"]]) == "foo"
assert _PruneMessage([1, {"x": [2, {"y": [3, 4]}]}]) == [1, {"x": [2, {"y": [3, 4]}]}]
assert _PruneMessage(
    {'a': 'b', 'c': 'd'}) == {'a': 'b', 'c': 'd'}
assert _PruneMessage({"foo": [1]}) == 1
assert _PruneMessage({"foo": {"bar": 1}}) == 1
assert _PruneMessage([1, {'a': 2}]) == [1, {'a': 2}]
assert _PruneMessage(-1) == -1
assert _PruneMessage([0, 1, 2]) == [0, 1, 2]
assert _PruneMessage(b'foo') == b'foo'
assert _PruneMessage('foo') == 'foo'
assert _PruneMessage(5) == 5
assert _PruneMessage([]) == []
assert _PruneMessage(42) == 42
assert _PruneMessage("hello") == "hello"
assert _PruneMessage({"x": 1, "y": 2, "z": 3}) == {"x": 1, "y": 2, "z": 3}
assert _PruneMessage(True) == True
assert _PruneMessage([None, None, None]) == [None, None, None]
assert _PruneMessage([['a']]) == 'a'
assert _PruneMessage(1.) == 1.
assert _PruneMessage((None,)) == (None,)
assert _PruneMessage({'1': 1, '2': 2, '3': 3}) == {'1': 1, '2': 2, '3': 3}
assert _PruneMessage([[None]]) == None
assert _PruneMessage(1.2) == 1.2
assert _PruneMessage((1,2,3)) == (1,2,3)
assert _PruneMessage((1,)) == (1,)
assert _PruneMessage({"a": "b", "c": "d"}) == {"a": "b", "c": "d"}
assert _PruneMessage(['test']) == 'test'
assert _PruneMessage('abc') == 'abc'
assert _PruneMessage({"a": "b", "c": "d", "e": "f"}) == {"a": "b", "c": "d", "e": "f"}
assert _PruneMessage([1,2,3]) == [1,2,3]
assert _PruneMessage({'1': 1, '2': 2, '3': 3, '4': 4}) == {'1': 1, '2': 2, '3': 3, '4': 4}
assert _PruneMessage(b'') == b''
assert _PruneMessage([1.0, 1.0]) == [1.0, 1.0]
assert _PruneMessage(()) == ()
assert _PruneMessage([True, False, False]) == [True, False, False]
assert _PruneMessage([None, 1]) == [None, 1]
assert _PruneMessage(["foo"]) == "foo"
assert _PruneMessage('') == ''
assert _PruneMessage([0, 1]) == [0, 1]
assert _PruneMessage([1.0]) == 1.0
assert _PruneMessage({'x':1,'y':2,'z':3}) == {'x':1,'y':2,'z':3}
assert _PruneMessage(1) == 1
assert _PruneMessage(['a', {'b': 1}]) == ['a', {'b': 1}]
assert _PruneMessage([-1, -1]) == [-1, -1]
assert _PruneMessage(-1.0) == -1.0
assert _PruneMessage(object) == object
assert _PruneMessage([1]) == 1
assert _PruneMessage([0, 0]) == [0, 0]
assert _PruneMessage({'1': 1, '2': 2}) == {'1': 1, '2': 2}
assert _PruneMessage([None, False]) == [None, False]
assert _PruneMessage('Hello, world.') == 'Hello, world.'
assert _PruneMessage(
    {'message': 'foo','metadata': {'bar': 1, 'baz': 2}}
) == {'message': 'foo','metadata': {'bar': 1, 'baz': 2}}
assert _PruneMessage([1., 2., 3.]) == [1., 2., 3.]
assert _PruneMessage('test') == 'test'
assert _PruneMessage([[1]]) == 1
assert _PruneMessage(frozenset()) == frozenset()
assert _PruneMessage(
    [{'message': 'foo','metadata': {'bar': 1, 'baz': 2}}]
) == {'message': 'foo','metadata': {'bar': 1, 'baz': 2}}
assert _PruneMessage([0, 1, 2, 3]) == [0, 1, 2, 3]
assert _PruneMessage([1, 2, 3, 4]) == [1, 2, 3, 4]
assert _PruneMessage(-float('inf')) == -float('inf')
assert _PruneMessage(0.0) == 0.0
assert _PruneMessage(b"a") == b"a"
assert _PruneMessage('') == ''
assert _PruneMessage(b"bar") == b"bar"
assert _PruneMessage([True, True]) == [True, True]
assert _PruneMessage({"foo": {"bar": [1, 2, 3]}}) == [1, 2, 3]
assert _PruneMessage(["hello", "world"]) == ["hello", "world"]
assert _PruneMessage([1, 2, 3]) == [1, 2, 3]
assert _PruneMessage({"a": 1, "b": 2}) == {"a": 1, "b": 2}
assert _PruneMessage("a") == "a"
assert _PruneMessage(
    ['hi']) == 'hi'
assert _PruneMessage([[1, 2, 3], [4, 5, 6]]) == [[1, 2, 3], [4, 5, 6]]
assert _PruneMessage([None, 1, 2]) == [None, 1, 2]
assert _PruneMessage(-1.0 - 2.0j) == -1.0 - 2.0j
assert _PruneMessage(
    {'a': [{'a': 1, 'b': 2}, {'a': 3, 'b': 4}], 'b': {'a': 5, 'b': 6}}) == {
        'a': [{'a': 1, 'b': 2}, {'a': 3, 'b': 4}],
        'b': {'a': 5, 'b': 6}}
assert _PruneMessage(['a', 'b']) == ['a', 'b']
assert _PruneMessage(3.14159) == 3.14159
assert _PruneMessage([1, 2]) == [1, 2]
assert _PruneMessage([True]) == True
assert _PruneMessage(dict()) == {}
assert _PruneMessage([[3]]) == 3
assert _PruneMessage({'a': 1, 'b': [2, 3, 4]}) == {'a': 1, 'b': [2, 3, 4]}
assert _PruneMessage(set()) == set()
assert _PruneMessage(False) == False
assert _PruneMessage([b'abc', b'def', b'ghi']) == [b'abc', b'def', b'ghi']
assert _PruneMessage({1: 2}) == 2
assert _PruneMessage(0.) == 0.
assert _PruneMessage('bar') == 'bar'
assert _PruneMessage(1.0 + 2.0j) == 1.0 + 2.0j
assert _PruneMessage([None, None]) == [None, None]
assert _PruneMessage(None) == None
assert _PruneMessage('string') =='string'
assert _PruneMessage('a') == 'a'
assert _PruneMessage(b'Hello, world.') == b'Hello, world.'
assert _PruneMessage(['a']) == 'a'
