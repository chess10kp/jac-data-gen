"""Convert a native string to a WSGI / HTTP compatible byte string."""
def wsgi_to_bytes(s: Any) -> object {
    return s.encode("iso-8859-1");
}

test "t0" {
    assert (wsgi_to_bytes("a") == b'a');;
}

test "t1" {
    assert (wsgi_to_bytes("\x00\x01\xff") == b'\x00\x01\xff');;
}

test "t2" {
    assert (wsgi_to_bytes("abcäöü") == b'abc\xe4\xf6\xfc');;
}

test "t3" {
    assert (wsgi_to_bytes("more_unicode") == b'more_unicode');;
}

test "t4" {
    assert (wsgi_to_bytes("abc\xff") == b'abc\xff');;
}

test "t5" {
    assert (wsgi_to_bytes("£") == wsgi_to_bytes("£"));;
}

test "t6" {
    assert (wsgi_to_bytes("£") == b'\xa3');;
}

test "t7" {
    assert (wsgi_to_bytes("abc\N{LATIN SMALL LETTER A WITH DIAERESIS}") == b'abc\xe4');;
}

test "t8" {
    assert (wsgi_to_bytes("hello") == b'hello');;
}

test "t9" {
    assert (wsgi_to_bytes("abc\xe4") == b'abc\xe4');;
}

test "t10" {
    assert (wsgi_to_bytes("") == b'');;
}

test "t11" {
    assert (wsgi_to_bytes("\x7f") == b'\x7f');;
}

test "t12" {
    assert (wsgi_to_bytes("foobar") == b'foobar');;
}

test "t13" {
    assert (wsgi_to_bytes("foo") == b'foo');;
}

test "t14" {
    assert (wsgi_to_bytes("\xe4") == b'\xe4');;
}

test "t15" {
    assert (wsgi_to_bytes("£") == wsgi_to_bytes("£"));;
}

test "t16" {
    assert (wsgi_to_bytes("a") == b'a');;
}

test "t17" {
    assert (wsgi_to_bytes("abc") == b'abc');;
}

test "t18" {
    assert (wsgi_to_bytes("\N{LATIN SMALL LETTER A WITH DIAERESIS}") == b'\xe4');;
}

test "t19" {
    assert (wsgi_to_bytes("foo") == b'foo');;
}

test "t20" {
    assert (wsgi_to_bytes("\xff\x00") == b'\xff\x00');;
}

test "t21" {
    assert (wsgi_to_bytes("test") == b'test');;
}

test "t22" {
    assert (wsgi_to_bytes("£") == b'\xa3');;
}

test "t23" {
    assert (wsgi_to_bytes("hello") == b'hello');;
}

test "t24" {
    assert (wsgi_to_bytes("Hello, World!") == b'Hello, World!');;
}

test "t25" {
    assert (wsgi_to_bytes("test") == b'test');;
}

test "t26" {
    assert (wsgi_to_bytes("Hello, World!\xe9") == b'Hello, World!\xe9');;
}

test "t27" {
    assert (wsgi_to_bytes('foo') == b'foo');;
}

test "t28" {
    assert (wsgi_to_bytes("abc") == b'abc');;
}

test "t29" {
    assert (wsgi_to_bytes("abc\xff") == b'abc\xff');;
}

test "t30" {
    assert (wsgi_to_bytes("\n") == b'\n');;
}

test "t31" {
    assert (wsgi_to_bytes("\n") == b'\n');;
}

test "t32" {
    assert (
        wsgi_to_bytes("\xe2\x82\xac\xe2\x82\xac\xe2\x82\xac")
        == b'\xe2\x82\xac\xe2\x82\xac\xe2\x82\xac'
    );;
}

test "t33" {
    assert (wsgi_to_bytes("£") == "£".encode("iso-8859-1"));;
}

test "t34" {
    assert (wsgi_to_bytes("abcd") == b'abcd');;
}

test "t35" {
    assert (wsgi_to_bytes("\xff") == b'\xff');;
}

test "t36" {
    assert (wsgi_to_bytes("\xff") == b'\xff');;
}

test "t37" {
    assert (wsgi_to_bytes("\x00") == b'\x00');;
}

test "t38" {
    assert (wsgi_to_bytes("\x01\x02\x03") == b'\x01\x02\x03');;
}

test "t39" {
    assert (wsgi_to_bytes("") == b'');;
}

test "t40" {
    assert (wsgi_to_bytes("£") == "£".encode("iso-8859-1"));;
}

test "t41" {
    assert (wsgi_to_bytes("unicode") == b'unicode');;
}

test "t42" {
    assert (wsgi_to_bytes("\x00\xff") == b'\x00\xff');;
}

test "t43" {
    assert (wsgi_to_bytes("abcd") == b'abcd');;
}

test "t44" {
    assert (wsgi_to_bytes("\x00\x01") == b'\x00\x01');;
}
