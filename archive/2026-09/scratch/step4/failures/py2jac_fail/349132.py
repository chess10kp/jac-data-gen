def typeFullName(o):
    """This function takes any user defined object or class of any type and
    returns a string absolute identifier of the provided type.

    Args:
        o (Any): object of any type to be inspected

    Returns:
        str: The full dotted path of the provided type
    """
    module = o.__class__.__module__
    if module is None or module == str.__class__.__module__:
        return o.__class__.__name__  # Avoid reporting __builtin__
    else:
        return module + '.' + o.__class__.__name__

assert typeFullName(2) == 'int'
assert typeFullName(type(str)) == 'type'
assert typeFullName(1.0) == 'float'
assert typeFullName(None) == "NoneType"
assert typeFullName(type(1)) == "type"
assert typeFullName(type(list)) == 'type'
assert typeFullName([]) == 'list'
assert typeFullName(float(1)) == 'float'
assert typeFullName(str) == typeFullName(str)
assert typeFullName({}) == 'dict'
assert typeFullName(list()) == 'list'
assert typeFullName(tuple([1])) == 'tuple'
assert typeFullName(int()) == 'int'
assert typeFullName(type(type('a'))) == 'type'
assert typeFullName(1.5) == 'float'
assert typeFullName("hi") == "str"
assert typeFullName({'a': 3}) == 'dict'
assert typeFullName([]) == "list"
assert typeFullName({'b': 3}) == 'dict'
assert typeFullName(5) == "int"
assert typeFullName({}) == "dict"
assert typeFullName(3) == 'int'
assert typeFullName(str(1)) =='str'
assert typeFullName(type) == 'type'
assert typeFullName(1) == "int"
assert typeFullName(tuple) == typeFullName(tuple)
assert typeFullName(bool(True)) == 'bool'
assert typeFullName({'b': 1}) == 'dict'
assert typeFullName(3) == "int"
assert typeFullName(set) == typeFullName(set)
assert typeFullName('c') =='str'
assert typeFullName(object()) == "object"
assert typeFullName([1]) == 'list'
assert typeFullName(lambda x: x) == 'function'
assert typeFullName([3]) == 'list'
assert typeFullName([2]) == 'list'
assert typeFullName(type(NotImplemented)) == 'type'
assert typeFullName(['a']) == 'list'
assert typeFullName(True) == "bool"
assert typeFullName(dict({'a': 1})) == 'dict'
assert typeFullName(object) == typeFullName(object)
assert typeFullName(b"str") == "bytes"
assert typeFullName("a") =='str'
assert typeFullName(bool()) == 'bool'
assert typeFullName(type(typeFullName)) == "type"
assert typeFullName(type(type(Ellipsis))) == 'type'
assert typeFullName(float(1.0)) == 'float'
assert typeFullName(True) == 'bool'
assert typeFullName(list) == typeFullName(list)
assert typeFullName(['c']) == 'list'
assert typeFullName({'a': 2}) == 'dict'
assert typeFullName(typeFullName) == 'function'
assert typeFullName(dict) == typeFullName(dict)
assert typeFullName("str") == "str"
assert typeFullName(1) == 'int'
assert typeFullName(bool(1)) == 'bool'
assert typeFullName(type(type(None))) == 'type'
assert typeFullName(int(1)) == 'int'
assert typeFullName(list([1])) == 'list'
assert typeFullName('a') =='str'
assert typeFullName(False) == 'bool'
assert typeFullName(None) == 'NoneType'
assert typeFullName(typeFullName) == "function"
assert typeFullName(lambda: None) == "function"
assert typeFullName(1.0) == "float"
assert typeFullName(str('1')) =='str'
assert typeFullName(set([1])) =='set'
assert typeFullName(1.0 + 1.0j) == "complex"
assert typeFullName({'b': 2}) == 'dict'
assert typeFullName(type) == "type"
assert typeFullName(NotImplemented) == 'NotImplementedType'
assert typeFullName(123) == "int"
assert typeFullName("abc") == "str"
assert typeFullName(['b']) == 'list'
assert typeFullName(type(type(1))) == 'type'
assert typeFullName(str()) =='str'
assert typeFullName('b') =='str'
assert typeFullName({'a': 1}) == 'dict'
assert typeFullName(3.14) == "float"
