"""Remove accents."""
def clean(s: str) -> str {
    return s.strip().replace("'", "");
}

test "t0" {
    assert (clean("test'''''''''") == "test");;
}

test "t1" {
    assert (clean("  a") == "a");;
}

test "t2" {
    assert (clean("test''") == "test");;
}

test "t3" {
    assert (clean("a ") == "a");;
}

test "t4" {
    assert (clean("'a") == "a");;
}

test "t5" {
    assert (clean("'a' ") == "a");;
}

test "t6" {
    assert (clean("a b c") == "a b c");;
}

test "t7" {
    assert (clean("test\n") == "test");;
}

test "t8" {
    assert (clean("  Dit is gewoon een test.  ") == "Dit is gewoon een test.");;
}

test "t9" {
    assert (clean(" 'a'") == "a");;
}

test "t10" {
    assert (clean("test\v") == "test");;
}

test "t11" {
    assert (clean("2'a") == "2a");;
}

test "t12" {
    assert (clean("a1'2") == "a12");;
}

test "t13" {
    assert (clean("1'2") == "12");;
}

test "t14" {
    assert (clean("a'1") == "a1");;
}

test "t15" {
    assert (clean("a'b'") == "ab");;
}

test "t16" {
    assert (clean("test''''''") == "test");;
}

test "t17" {
    assert (clean("Dit is gewoon een test.") == "Dit is gewoon een test.");;
}

test "t18" {
    assert (clean("    a     ") == "a");;
}

test "t19" {
    assert (clean("test\n\n") == "test");;
}

test "t20" {
    assert (clean("test''''''''") == "test");;
}

test "t21" {
    assert (clean("test\f") == "test");;
}

test "t22" {
    assert (clean("test\t") == "test");;
}

test "t23" {
    assert (clean("1'a") == "1a");;
}

test "t24" {
    assert (clean("test'''''''") == "test");;
}

test "t25" {
    assert (clean("'a'") == "a");;
}

test "t26" {
    assert (clean(" a") == "a");;
}

test "t27" {
    assert (clean('123 456') == "123 456");;
}

test "t28" {
    assert (clean("test'''") == "test");;
}

test "t29" {
    assert (clean('abc def') == "abc def");;
}

test "t30" {
    assert (clean("a'2") == "a2");;
}

test "t31" {
    assert (
        clean("Dit is gewoon een test. Je zal niet de zin vinden...")
        == "Dit is gewoon een test. Je zal niet de zin vinden..."
    );;
}

test "t32" {
    assert (clean("test''''") == "test");;
}

test "t33" {
    assert (clean("    'a'     ") == "a");;
}

test "t34" {
    assert (clean(" a ") == "a");;
}

test "t35" {
    assert (clean(" 'a' ") == "a");;
}

test "t36" {
    assert (clean("test\r\n") == "test");;
}

test "t37" {
    assert (clean("test\n\n\n") == "test");;
}

test "t38" {
    assert (clean("a") == "a");;
}

test "t39" {
    assert (clean("test\t\t") == "test");;
}

test "t40" {
    assert (clean("test'") == "test");;
}

test "t41" {
    assert (clean("") == "");;
}

test "t42" {
    assert (clean("test\t\t\t") == "test");;
}

test "t43" {
    assert (clean(" test ") == "test");;
}
