def getClass(obj):
    """
    Return the class or type of object 'obj'.
    Returns sensible result for oldstyle and newstyle instances and types.
    """
    if hasattr(obj, '__class__'):
        return obj.__class__
    else:
        return type(obj)

assert getClass(100.0) == float
assert getClass(frozenset([1,2,3])) == frozenset
assert getClass(42.0) == float
assert getClass("hello") == str
assert getClass([1,2,3]) == list
assert getClass(Exception) == type(Exception)
assert getClass(set()) == set
assert getClass(1.0) == float
assert getClass(str) == getClass(type(str))
assert getClass(Ellipsis) == type(Ellipsis)
assert getClass(dict()) == dict
assert getClass(1.) == float
assert getClass(5) == int
assert getClass(list()) == list
assert getClass(int) == type
assert getClass(dict) == getClass(type(dict))
assert getClass(set([1,2,3])) == set
assert getClass("foo") == str
assert getClass({1: 2, 3: 4}) == dict
assert getClass(1) == int
assert getClass('') == str
assert getClass('hello') == str
assert getClass((1, 2, 3)) == tuple
assert getClass(getClass) == type(getClass)
assert getClass({1:2,3:4}) == dict
assert getClass(object()) == object
assert getClass(float) == type
assert getClass(1j) == complex
assert getClass(set) == getClass(type(set))
assert getClass(len) == type(len)
assert getClass(tuple()) == tuple
assert getClass([]) == list
assert getClass(dict) == type
assert getClass(False) == bool
assert getClass(complex(1, 2)) == complex
assert getClass(3) == int
assert getClass({1:2, 3:4}) == dict
assert getClass(slice) == type
assert getClass(Exception()) == Exception
assert getClass(1.0+0j) == complex
assert getClass({1, 2, 3}) == set
assert getClass(set) == type
assert getClass([1]) == list
assert getClass('100') == str
assert getClass(int(0)) == int
assert getClass(Exception) == type
assert getClass(object) == type
assert getClass(1+0j) == complex
assert getClass(1 + 2j) == complex
assert getClass(frozenset()) == frozenset
assert getClass(complex) == type
assert getClass({}) == dict
assert getClass((1,2,3)) == tuple
assert getClass('spam') == str
assert getClass(True) == bool
assert getClass(0.0) == float
assert getClass(int) == type(int)
assert getClass(str) == type(str)
assert getClass([1, 2]) == list
assert getClass(None) == type(None)
assert getClass('foo') == str
assert getClass(str) == type
assert getClass(dict) == type(dict)
assert getClass(float(0)) == float
assert getClass(type('C', (), {})) == type
assert getClass(1+2j) == complex
assert getClass(set) == type(set)
assert getClass(tuple) == type
assert getClass(10) == int
assert getClass(str()) == str
assert getClass(int()) == int
assert getClass(float) == getClass(type(float))
assert getClass(int) == getClass(type(int))
assert getClass(frozenset([1, 2, 3])) == frozenset
assert getClass(1.1) == float
assert getClass(()) == tuple
assert getClass(abs) == type(abs)
assert getClass([1, 2, 3]) == list
assert getClass(bool) == type(bool)
assert getClass(3.14159) == float
assert getClass(slice(0)) == slice
assert getClass(bool) == getClass(type(bool))
assert getClass(type) == type
assert getClass(100) == int
assert getClass(3.14) == float
assert getClass(frozenset) == type
assert getClass(float()) == float
assert getClass(1+1j) == complex
assert getClass(list) == type
assert getClass('string') == str
assert getClass(complex()) == complex
assert getClass(42) == int
assert getClass(float) == type(float)
assert getClass(42.0+0j) == complex
assert getClass((1, 2)) == tuple
