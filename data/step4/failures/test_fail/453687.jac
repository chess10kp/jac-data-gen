"""Return a set of strings."""
def _split_comma_separated(string: Any) -> object {
    return `set(filter(None, string.split(',')));
}

test "t0" {
    assert (_split_comma_separated('a,b,,c') == {'a', 'b', 'c'});;
}

test "t1" {
    assert (_split_comma_separated(',a') == {'a'});;
}

test "t2" {
    assert (_split_comma_separated("a,b") == {"a", "b"});;
}

test "t3" {
    assert (_split_comma_separated('foo') == {'foo'});;
}

test "t4" {
    assert (_split_comma_separated(',a,b') == {'a', 'b'});;
}

test "t5" {
    assert (_split_comma_separated('a,b') == {'a', 'b'});;
}

test "t6" {
    assert (_split_comma_separated(',a,b,') == {'a', 'b'});;
}

test "t7" {
    assert (_split_comma_separated('a,') == {'a'});;
}

test "t8" {
    assert (_split_comma_separated('foo') == {'foo'});;
}

test "t9" {
    assert (_split_comma_separated('foo,') == {'foo'});;
}

test "t10" {
    assert (_split_comma_separated('a') == {'a'});;
}

test "t11" {
    assert (_split_comma_separated(',foo') == {'foo'});;
}

test "t12" {
    assert (_split_comma_separated(",,a,,b,") == {'a', 'b'});;
}

test "t13" {
    assert (_split_comma_separated('a,b,') == {'a', 'b'});;
}

test "t14" {
    assert (_split_comma_separated('') == `set());;
}

test "t15" {
    assert (_split_comma_separated('') == `set());;
}

test "t16" {
    assert (_split_comma_separated('a,b,c') == {'a', 'b', 'c'});;
}

test "t17" {
    assert (_split_comma_separated("a,b") == {'a', 'b'});;
}

test "t18" {
    assert (_split_comma_separated(",,,,") == `set());;
}

test "t19" {
    assert (_split_comma_separated("a") == {"a"});;
}

test "t20" {
    assert (_split_comma_separated("a") == {'a'});;
}

test "t21" {
    assert (_split_comma_separated(",,") == `set());;
}

test "t22" {
    assert (_split_comma_separated(',foo,bar,') == {'foo', 'bar'});;
}

test "t23" {
    assert (
        _split_comma_separated("a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z")
        == {
            'a',
            'b',
            'c',
            'd',
            'e',
            'f',
            'g',
            'h',
            'i',
            'j',
            'k',
            'l',
            'm',
            'n',
            'o',
            'p',
            'q',
            'r',
            's',
            't',
            '',
            'v',
            'w',
            'x',
            'y',
            'z'
        }
    );;
}

test "t24" {
    assert (_split_comma_separated('foo,bar') == {'foo', 'bar'});;
}

test "t25" {
    assert (_split_comma_separated("") == `set());;
}

test "t26" {
    assert (_split_comma_separated(",,a,,b,c") == {"a", "b", "c"});;
}

test "t27" {
    assert (_split_comma_separated('a,b,,c,') == {'a', 'b', 'c'});;
}
