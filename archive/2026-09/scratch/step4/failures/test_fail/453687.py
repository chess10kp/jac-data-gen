def _split_comma_separated(string):
    """Return a set of strings."""
    return set(filter(None, string.split(',')))

assert _split_comma_separated('a,b,,c') == {'a', 'b', 'c'}
assert _split_comma_separated(',a') == {'a'}
assert _split_comma_separated("a,b") == {"a", "b"}
assert _split_comma_separated(
    'foo'
) == {'foo'}
assert _split_comma_separated(',a,b') == {'a', 'b'}
assert _split_comma_separated('a,b') == {'a', 'b'}
assert _split_comma_separated(',a,b,') == {'a', 'b'}
assert _split_comma_separated('a,') == {'a'}
assert _split_comma_separated('foo') == {'foo'}
assert _split_comma_separated('foo,') == {'foo'}
assert _split_comma_separated('a') == {'a'}
assert _split_comma_separated(',foo') == {'foo'}
assert _split_comma_separated(",,a,,b,") == {'a', 'b'}
assert _split_comma_separated('a,b,') == {'a', 'b'}
assert _split_comma_separated(
    ''
) == set()
assert _split_comma_separated('') == set()
assert _split_comma_separated('a,b,c') == {'a', 'b', 'c'}
assert _split_comma_separated("a,b") == {'a', 'b'}
assert _split_comma_separated(",,,,") == set()
assert _split_comma_separated("a") == {"a"}
assert _split_comma_separated("a") == {'a'}
assert _split_comma_separated(",,") == set()
assert _split_comma_separated(',foo,bar,') == {'foo', 'bar'}
assert _split_comma_separated("a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z") == {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l','m', 'n', 'o', 'p', 'q', 'r','s', 't', '', 'v', 'w', 'x', 'y', 'z'}
assert _split_comma_separated('foo,bar') == {'foo', 'bar'}
assert _split_comma_separated("") == set()
assert _split_comma_separated(",,a,,b,c") == {"a", "b", "c"}
assert _split_comma_separated('a,b,,c,') == {'a', 'b', 'c'}
