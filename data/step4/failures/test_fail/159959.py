def has_methods(widget, methods_sets):
    """
    Chick if the widget has methods from given set.

    `methods_sets` is a list of method sets. The function returns ``True`` iff the widget has at least one method from each of the sets.
    """
    for ms in methods_sets:
        if not any([hasattr(widget,m) for m in ms]):
            return False
    return True

assert has_methods(None, [["method1","method2"]]) == False
assert has_methods(0, {'foo', 'bar'}) == False
assert has_methods(None, [[], ["pack"]]) == False
assert has_methods(None, [["method"]]) == False
assert has_methods(None, [["method1","method2"],["method3"]]) == False
assert has_methods('hello', {'foo', 'bar'}) == False
assert has_methods(has_methods, {has_methods, 'foo'}) == False
assert has_methods(None, [["method1"],["method2"]]) == False
assert has_methods(None, [["method1"],["method2"],["method3"]]) == False
