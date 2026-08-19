"""
    Chick if the widget has methods from given set.

    `methods_sets` is a list of method sets. The function returns ``True`` iff the widget has at least one method from each of the sets.
    """
def has_methods(widget: Any, methods_sets: Any) -> object {
    for ms in methods_sets {
        if not `any([hasattr(widget, m) for m in ms]) {
            return False;
        }
    }
    return True;
}

test "t0" {
    assert (has_methods(None, [["method1", "method2"]]) == False);;
}

test "t1" {
    assert (has_methods(0, {'foo', 'bar'}) == False);;
}

test "t2" {
    assert (has_methods(None, [[], ["pack"]]) == False);;
}

test "t3" {
    assert (has_methods(None, [["method"]]) == False);;
}

test "t4" {
    assert (has_methods(None, [["method1", "method2"], ["method3"]]) == False);;
}

test "t5" {
    assert (has_methods('hello', {'foo', 'bar'}) == False);;
}

test "t6" {
    assert (has_methods(has_methods, {has_methods, 'foo'}) == False);;
}

test "t7" {
    assert (has_methods(None, [["method1"], ["method2"]]) == False);;
}

test "t8" {
    assert (has_methods(None, [["method1"], ["method2"], ["method3"]]) == False);;
}
