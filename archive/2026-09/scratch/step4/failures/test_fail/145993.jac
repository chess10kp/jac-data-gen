"""
    Invoke ``function`` with ``value`` and other arguments, return ``value``.

    Use this to add a function to a callback chain without disrupting the
    value of the callback chain::

        d = defer.succeed(42)
        d.addCallback(transparent, print)
        d.addCallback(lambda x: x == 42)
    """
def transparent(value: Any, function: Any, *args: Any, **kwargs: Any) -> object {
    function(value, *args, **kwargs);
    return value;
}

test "t0" {
    assert (transparent(42, print, 42, 24, 64, 256, 1024) == 42);;
}

test "t1" {
    assert (transparent(42, lambda (x: Any) { x; }) == 42);;
}

test "t2" {
    assert (transparent(42, print, 42, 24, 64, 256, 1024, 4096) == 42);;
}

test "t3" {
    assert (transparent(42, print, 42, 24, 64) == 42);;
}

test "t4" {
    assert (transparent(1, lambda (x: Any, y: Any) { None; }, 2) == 1);;
}

test "t5" {
    assert (transparent(1, print, "foo") == 1);;
}

test "t6" {
    assert (transparent(1, lambda (x: Any) { x; }) == 1);;
}

test "t7" {
    assert (transparent(42, lambda (value: Any) { value; }) == 42);;
}

test "t8" {
    assert (transparent(1, lambda (x: Any, y: Any = 3) { None; }, 2) == 1);;
}

test "t9" {
    assert (transparent(1, lambda (*x: Any, **y: Any) { None; }, 2) == 1);;
}

test "t10" {
    assert (transparent(1, print, 2) == 1);;
}

test "t11" {
    assert (transparent(0, print, 1, 2, 3) == 0);;
}

test "t12" {
    assert (transparent(1, lambda (x: Any, *y: Any) { None; }, 2) == 1);;
}

test "t13" {
    assert (transparent(1, lambda (v: Any, v2: Any) { None; }, 1) == 1);;
}

test "t14" {
    assert (transparent(1, lambda (x: Any, y: Any) { x; }, 1) == 1);;
}

test "t15" {
    assert (transparent(1, lambda (*args: Any) { args[0]; }, 2) == 1);;
}

test "t16" {
    assert (transparent(42, print, 42, 24) == 42);;
}

test "t17" {
    assert (transparent(1, print, "foo", "bar") == 1);;
}

test "t18" {
    assert (transparent(1, lambda (v: Any) { None; }) == 1);;
}

test "t19" {
    assert (transparent(1, lambda (v: Any, v2: Any = 2) { None; }, 1) == 1);;
}

test "t20" {
    assert (transparent(1, print, 1) == 1);;
}

test "t21" {
    assert (transparent(1, lambda (x: Any = 2, y: Any = 3) { None; }) == 1);;
}

test "t22" {
    assert (transparent(0, print, 1) == 0);;
}

test "t23" {
    assert (transparent(1, lambda (v: Any) { v; }) == 1);;
}

test "t24" {
    assert (
        transparent(42, lambda (x: Any, y: Any, z: Any) { (x + y + z); }, 1, 2) == 42
    );;
}

test "t25" {
    assert (transparent(1, lambda (x: Any, y: Any = 1) { None; }, 2) == 1);;
}

test "t26" {
    assert (transparent(0, print) == 0);;
}

test "t27" {
    assert (transparent(1, lambda (*args: Any) { args[0]; }) == 1);;
}

test "t28" {
    assert (transparent(1, print, 2, 3) == 1);;
}

test "t29" {
    assert (transparent(42, print) == 42);;
}

test "t30" {
    assert (transparent(1, lambda (x: Any, **kwargs: Any) { None; }) == 1);;
}

test "t31" {
    assert (transparent(42, lambda (x: Any) { None; }) == 42);;
}

test "t32" {
    assert (transparent(42, print, 42, 24, 64, 256) == 42);;
}

test "t33" {
    assert (transparent(42, lambda (x: Any, y: Any) { None; }, 43) == 42);;
}

test "t34" {
    assert (transparent(1, print, "one") == 1);;
}

test "t35" {
    assert (transparent(42, print, 42) == 42);;
}

test "t36" {
    assert (transparent(1, print) == 1);;
}

test "t37" {
    assert (transparent(1, lambda (x: Any, y: Any) { x; }, 2) == 1);;
}

test "t38" {
    assert (transparent(1, lambda (x: Any, **kwargs: Any) { x; }) == 1);;
}

test "t39" {
    assert (transparent(1, lambda (x: Any, y: Any = 2) { y; }) == 1);;
}

test "t40" {
    assert (transparent(1, lambda (v: Any, v2: Any = 2) { None; }) == 1);;
}

test "t41" {
    assert (transparent(42, lambda (x: Any, **kwargs: Any) { x; }) == 42);;
}

test "t42" {
    assert (transparent(1, print, 1, 2) == 1);;
}

test "t43" {
    assert (transparent(1, lambda (x: Any, *args: Any) { x; }) == 1);;
}

test "t44" {
    assert (transparent(1, lambda (x: Any) { None; }) == 1);;
}

test "t45" {
    assert (transparent(1, lambda (x: Any = 2) { x; }) == 1);;
}

test "t46" {
    assert (transparent(1, lambda (x: Any = 1) { None; }) == 1);;
}
