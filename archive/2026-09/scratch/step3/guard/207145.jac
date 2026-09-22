"""Return whether the given status name is frozen."""
def isFrozen(status: str) -> bool {
    return status.startswith('.');
}

test "t0" {
    assert (isFrozen('foo bar') == False);;
}

test "t1" {
    assert (isFrozen("") == False);;
}

test "t2" {
    assert (isFrozen('foo.bar..') == False);;
}

test "t3" {
    assert (isFrozen('.foo.') == True);;
}

test "t4" {
    assert (isFrozen("foo.bar.baz") == False);;
}

test "t5" {
    assert (isFrozen('') == False);;
}

test "t6" {
    assert (isFrozen("foo.bar") == False);;
}

test "t7" {
    assert (isFrozen('foo.bar....') == False);;
}

test "t8" {
    assert (isFrozen(".foo") == True);;
}

test "t9" {
    assert (isFrozen('.foo bar baz') == True);;
}

test "t10" {
    assert (isFrozen('a..') == False);;
}

test "t11" {
    assert (isFrozen('.abc') == True);;
}

test "t12" {
    assert (isFrozen('frozen') == False);;
}

test "t13" {
    assert (isFrozen(".foo") == True);;
}

test "t14" {
    assert (isFrozen('zA') == False);;
}

test "t15" {
    assert (isFrozen('.foo') == True);;
}

test "t16" {
    assert (isFrozen('A') == False);;
}

test "t17" {
    assert (isFrozen("foo.bar.baz") == False);;
}

test "t18" {
    assert (isFrozen('foo.bar.') == False);;
}

test "t19" {
    assert (isFrozen(".foo.bar.baz") == True);;
}

test "t20" {
    assert (isFrozen("foo") == False);;
}

test "t21" {
    assert (isFrozen(".foo.bar") == True);;
}

test "t22" {
    assert (isFrozen("foo.bar") == False);;
}

test "t23" {
    assert (isFrozen('foo bar baz') == False);;
}

test "t24" {
    assert (isFrozen("foo.bar.baz.quux") == False);;
}

test "t25" {
    assert (isFrozen('.foo.bar.baz.quux') == True);;
}

test "t26" {
    assert (isFrozen("foo") == False);;
}

test "t27" {
    assert (isFrozen('.X') == True);;
}

test "t28" {
    assert (isFrozen('.Y') == True);;
}

test "t29" {
    assert (isFrozen('foo.bar.baz') == False);;
}

test "t30" {
    assert (isFrozen('.foo.bar') == True);;
}

test "t31" {
    assert (isFrozen('foo.bar.baz.quux') == False);;
}

test "t32" {
    assert (isFrozen('bzr') == False);;
}

test "t33" {
    assert (isFrozen(' ') == False);;
}

test "t34" {
    assert (isFrozen('.frozen') == True);;
}

test "t35" {
    assert (isFrozen(".foo.bar.baz.quux") == True);;
}

test "t36" {
    assert (isFrozen('.M') == True);;
}

test "t37" {
    assert (isFrozen('.') == True);;
}

test "t38" {
    assert (isFrozen('a') == False);;
}

test "t39" {
    assert (isFrozen('foo..bar') == False);;
}

test "t40" {
    assert (isFrozen('foo') == False);;
}

test "t41" {
    assert (isFrozen('.foo bar') == True);;
}

test "t42" {
    assert (isFrozen('. ') == True);;
}

test "t43" {
    assert (isFrozen('.first') == True);;
}

test "t44" {
    assert (isFrozen('.foo.bar.baz') == True);;
}

test "t45" {
    assert (isFrozen('unfrozen') == False);;
}

test "t46" {
    assert (isFrozen('..foo') == True);;
}

test "t47" {
    assert (isFrozen('..foo.bar') == True);;
}

test "t48" {
    assert (isFrozen('abc') == False);;
}

test "t49" {
    assert (isFrozen('.Z') == True);;
}

test "t50" {
    assert (isFrozen('first') == False);;
}

test "t51" {
    assert (isFrozen('foo..bar.') == False);;
}

test "t52" {
    assert (isFrozen('foo.bar') == False);;
}

