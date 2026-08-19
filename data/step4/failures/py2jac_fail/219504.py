def is_kind_of_class(obj, a_class):
    """ checks class inheritance
        Args:
            obj: object to evaluate
            a_class: suspect father
    """

    return isinstance(obj, a_class)

assert is_kind_of_class(float, object) == True
assert is_kind_of_class(5, str) == False
assert is_kind_of_class(1, object) == True
assert is_kind_of_class(int, type) == True
assert is_kind_of_class(1.0, set) == False
assert is_kind_of_class(1, int) == True
assert is_kind_of_class(lambda x: x**2, object) == True
assert is_kind_of_class(list(), dict) == False
assert is_kind_of_class(3.5, float) == True
assert is_kind_of_class('3', float) == False
assert is_kind_of_class(5.0j, str) == False
assert is_kind_of_class(123, int) == True
assert is_kind_of_class(set(), int) == False
assert is_kind_of_class([], int) == False
assert is_kind_of_class(False, bool) == True
assert is_kind_of_class(1.0 + 2j, dict) == False
assert is_kind_of_class("hello", (int, float)) == False
assert is_kind_of_class("Hello", str) == True
assert is_kind_of_class(1, dict) == False
assert is_kind_of_class([], (int, str, float, list)) == True
assert is_kind_of_class("hello", float) == False
assert is_kind_of_class(1000, list) == False
assert is_kind_of_class(int, float) == False
assert is_kind_of_class(type, object) == True
assert is_kind_of_class(type, type) == True
assert is_kind_of_class(1, (str, float)) == False
assert is_kind_of_class("hello", str) == True
assert is_kind_of_class(str, object) == True
assert is_kind_of_class(list(), int) == False
assert is_kind_of_class(5, float) == False
assert is_kind_of_class(object, object) == True
assert is_kind_of_class('3', int) == False
assert is_kind_of_class("foo", list) == False
assert is_kind_of_class(1.0 + 2j, set) == False
assert is_kind_of_class("str", (int, str, float, list)) == True
assert is_kind_of_class(3.5, int) == False
assert is_kind_of_class(3, int) == True
assert is_kind_of_class(tuple(), int) == False
assert is_kind_of_class(list(), list) == True
assert is_kind_of_class(int, str) == False
assert is_kind_of_class("hello", (int, str)) == True
assert is_kind_of_class(123, float) == False
assert is_kind_of_class(1.0 + 2j, str) == False
assert is_kind_of_class(5.0j, float) == False
assert is_kind_of_class(object(), int) == is_kind_of_class(object(), int)
assert is_kind_of_class("str", int) == False
assert is_kind_of_class(1, (int, str)) == True
assert is_kind_of_class("str", (str, float)) == True
assert is_kind_of_class("hi", int) == False
assert is_kind_of_class(5, (float, int)) == True
assert is_kind_of_class(193, int) == True
assert is_kind_of_class(dict(), set) == False
assert is_kind_of_class(1.0, dict) == False
assert is_kind_of_class(1.0, str) == False
assert is_kind_of_class(1.0, list) == False
assert is_kind_of_class("Hello", int) == False
assert is_kind_of_class(dict(), dict) == True
assert is_kind_of_class(int, complex) == False
assert is_kind_of_class(3, str) == False
assert is_kind_of_class([1, 2, 3], list) == True
assert is_kind_of_class(is_kind_of_class, int) == False
assert is_kind_of_class(float, int) == False
assert is_kind_of_class('3', type) == False
assert is_kind_of_class(set(), dict) == False
assert is_kind_of_class(str, int) == False
assert is_kind_of_class("Hello", complex) == False
assert is_kind_of_class(1.5, object) == True
assert is_kind_of_class(9.0, int) == False
assert is_kind_of_class('a', object) == True
assert is_kind_of_class("hello", object) == True
assert is_kind_of_class(str(), int) == False
assert is_kind_of_class(1, set) == False
assert is_kind_of_class("hello", int) == False
assert is_kind_of_class("foo", str) == True
assert is_kind_of_class(1, complex) == False
assert is_kind_of_class(1.0 + 2j, int) == False
assert is_kind_of_class(1.0, float) == True
assert is_kind_of_class([], list) == True
assert is_kind_of_class("hello", (str, int)) == True
assert is_kind_of_class(5.0j, complex) == True
assert is_kind_of_class(5, (int, float)) == True
assert is_kind_of_class(5, (int, str)) == True
assert is_kind_of_class(1000, object) == True
assert is_kind_of_class(1, (int, str, float)) == True
assert is_kind_of_class(int, object) == True
assert is_kind_of_class(5.0, complex) == False
assert is_kind_of_class(object(), int) == False
assert is_kind_of_class(1.0, int) == False
assert is_kind_of_class(3, type) == False
assert is_kind_of_class(float, str) == False
assert is_kind_of_class(float, complex) == False
assert is_kind_of_class(1.0, complex) == False
assert is_kind_of_class(dict(), list) == False
assert is_kind_of_class(1, float) == False
assert is_kind_of_class(3, float) == False
assert is_kind_of_class("Hello", float) == False
assert is_kind_of_class("hello", dict) == False
assert is_kind_of_class(1.5, int) == False
assert is_kind_of_class(tuple(), tuple) == True
assert is_kind_of_class(5.0, float) == True
assert is_kind_of_class(None, object) == True
assert is_kind_of_class({1: "one", 2: "two", 3: "three"}, dict) == True
assert is_kind_of_class("hello", (str, float)) == True
assert is_kind_of_class(1.5, (int, str)) == False
assert is_kind_of_class(1000, dict) == False
assert is_kind_of_class("hi", str) == True
assert is_kind_of_class(float, type) == True
assert is_kind_of_class(object(), object) == True
assert is_kind_of_class(tuple(), dict) == False
assert is_kind_of_class(str, (int, float)) == False
assert is_kind_of_class(5.0j, int) == False
assert is_kind_of_class('3', str) == True
assert is_kind_of_class(5.0, int) == False
assert is_kind_of_class(3.5, str) == False
assert is_kind_of_class(str(), str) == True
assert is_kind_of_class("str", (int, str, float)) == True
assert is_kind_of_class(3.5, type) == False
assert is_kind_of_class(True, bool) == True
assert is_kind_of_class(5.0, str) == False
assert is_kind_of_class(1, str) == False
assert is_kind_of_class(dict(), int) == False
assert is_kind_of_class(dict(), tuple) == False
assert is_kind_of_class(1.0 + 2j, float) == False
assert is_kind_of_class(1.0 + 2j, list) == False
assert is_kind_of_class(5, complex) == False
assert is_kind_of_class(set(), set) == True
assert is_kind_of_class(1, list) == False
assert is_kind_of_class(str, type) == True
assert is_kind_of_class("hello", list) == False
