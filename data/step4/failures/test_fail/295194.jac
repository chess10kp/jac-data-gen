"""Set the _use_oauth keyword argument to True when appropriate.

    This is needed because generator functions may be called at anytime, and
    PRAW relies on the Reddit._use_oauth value at original call time to know
    when to make OAuth requests.

    Returned data is not modified.

    """
def oauth_generator(function: Any, *args: Any, **kwargs: Any) -> object {
    if getattr(args[0], '_use_oauth', False) {
        kwargs['_use_oauth'] = True;
    }
    return function(*args, **kwargs);
}

test "t0" {
    assert (oauth_generator(lambda (x: Any) { x; }, 1) == 1);;
}

test "t1" {
    assert (oauth_generator(lambda (x: Any, y: Any) { 42; }, 42, 43) == 42);;
}

test "t2" {
    assert (oauth_generator(lambda (x: Any, y: Any, z: Any) { 42; }, 42, 43, 44) == 42);;
}

test "t3" {
    assert (
        oauth_generator(
            lambda (
                a: Any, b: Any, c: Any, d: Any, e: Any, f: Any, g: Any, h: Any, i: Any
            ) { [a, b, c, d, e, f, g, h, i]; },
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9
        )
        == [1, 2, 3, 4, 5, 6, 7, 8, 9]
    );;
}

test "t4" {
    assert (
        oauth_generator(lambda (s: Any) { s.split(); }, "a b c") == ['a', 'b', 'c']
    );;
}

test "t5" {
    assert (
        oauth_generator(
            lambda (a: Any, b: Any, _use_oauth: Any = False) { [a, b]; }, 1, 2
        )
        == [1, 2]
    );;
}

test "t6" {
    assert (
        oauth_generator(
            lambda (a: Any, b: Any, _use_oauth: Any = True) { [a, b]; }, 1, 2
        )
        == [1, 2]
    );;
}

test "t7" {
    assert (oauth_generator(lambda (a: Any, b: Any) { [a, b]; }, 1, 2) == [1, 2]);;
}

test "t8" {
    assert (
        oauth_generator(
            lambda (x: Any, y: Any, z: Any, a: Any, b: Any = 4, *c: Any) { (
                x,
                y,
                z,
                a,
                b,
                c
            ); },
            1,
            2,
            3,
            4
        )
        == (1, 2, 3, 4, 4, ())
    );;
}

test "t9" {
    assert (
        oauth_generator(
            lambda (x: Any, y: Any, _use_oauth: Any = True) { (x + y); }, 1, 2
        )
        == 3
    );;
}

test "t10" {
    assert (
        oauth_generator(
            lambda (x: Any, y: Any, z: Any, a: Any) { (x, y, z, a); }, 1, 2, 3, 4
        )
        == (1, 2, 3, 4)
    );;
}

test "t11" {
    assert (oauth_generator(`list, []) == []);;
}

test "t12" {
    assert (oauth_generator(lambda (x: Any) { x; }, None) == None);;
}

test "t13" {
    assert (oauth_generator(lambda (x: Any) { x; }, "test") == "test");;
}

test "t14" {
    assert (oauth_generator(lambda (x: Any) { 42; }, 42) == 42);;
}

test "t15" {
    assert (oauth_generator(lambda (x: Any) { x; }, 2) == 2);;
}

test "t16" {
    assert (
        oauth_generator(
            lambda (x: Any, y: Any, _use_oauth: Any = False) { (x + y); }, 1, 2
        )
        == 3
    );;
}

test "t17" {
    assert (oauth_generator(lambda (*args: Any) { args; }, 1, 2, 3) == (1, 2, 3));;
}

test "t18" {
    assert (oauth_generator(lambda (x: Any, y: Any) { (x + y); }, 1, 2) == 3);;
}

test "t19" {
    assert (
        oauth_generator(
            lambda (x: Any, y: Any, z: Any, a: Any, b: Any = 4, **d: Any) { (
                x,
                y,
                z,
                a,
                b,
                d
            ); },
            1,
            2,
            3,
            4
        )
        == (1, 2, 3, 4, 4, {})
    );;
}

test "t20" {
    assert (
        oauth_generator(
            lambda (x: Any, y: Any, z: Any, a: Any, b: Any = 4, *c: Any, **d: Any) { (
                x,
                y,
                z,
                a,
                b,
                c,
                d
            ); },
            1,
            2,
            3,
            4
        )
        == (1, 2, 3, 4, 4, (), {})
    );;
}

test "t21" {
    assert (oauth_generator(lambda (x: Any, y: Any) { (x + y); }, 2, 3) == 5);;
}

test "t22" {
    assert (oauth_generator(lambda (x: Any) { x; }, [None]) == [None]);;
}

test "t23" {
    assert (
        oauth_generator(lambda (x: Any, y: Any) { y; }, "test", "test2") == "test2"
    );;
}

test "t24" {
    assert (
        oauth_generator(lambda (reddit: Any, x: Any) { x; }, object(), 'foo') == 'foo'
    );;
}

test "t25" {
    assert (
        oauth_generator(
            lambda (x: Any, y: Any, z: Any, a: Any, b: Any = 4) { (x, y, z, a, b); },
            1,
            2,
            3,
            4
        )
        == (1, 2, 3, 4, 4)
    );;
}
