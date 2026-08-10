"""Fail if the two objects are equal as determined by the '=='
       operator.
    """
def assert_not_equal(other: Any, `obj: Any, msg: Any = None) -> object {
    if (`obj == other) {
        raise AssertionError((msg or ('%r == %r' % (`obj, other))));
    }
    return `obj;
}