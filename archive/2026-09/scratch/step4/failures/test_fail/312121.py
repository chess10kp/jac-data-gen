def clean(s: str) -> str:
    """Remove accents."""
    return s.strip().replace("'", "")

assert clean(
    "test'''''''''") == "test"
assert clean("  a") == "a"
assert clean(
    "test''") == "test"
assert clean("a ") == "a"
assert clean("'a") == "a"
assert clean("'a' ") == "a"
assert clean("a b c") == "a b c"
assert clean(
    "test\n") == "test"
assert clean("  Dit is gewoon een test.  ") == "Dit is gewoon een test."
assert clean(" 'a'") == "a"
assert clean(
    "test\v") == "test"
assert clean("2'a") == "2a"
assert clean("a1'2") == "a12"
assert clean("1'2") == "12"
assert clean("a'1") == "a1"
assert clean("a'b'") == "ab"
assert clean(
    "test''''''") == "test"
assert clean("Dit is gewoon een test.") == "Dit is gewoon een test."
assert clean(
    "    a     ") == "a"
assert clean(
    "test\n\n") == "test"
assert clean(
    "test''''''''") == "test"
assert clean(
    "test\f") == "test"
assert clean(
    "test\t") == "test"
assert clean("1'a") == "1a"
assert clean(
    "test'''''''") == "test"
assert clean("'a'") == "a"
assert clean(" a") == "a"
assert clean('123 456') == "123 456"
assert clean(
    "test'''") == "test"
assert clean('abc def') == "abc def"
assert clean("a'2") == "a2"
assert clean(
    "Dit is gewoon een test. Je zal niet de zin vinden..."
) == "Dit is gewoon een test. Je zal niet de zin vinden..."
assert clean(
    "test''''") == "test"
assert clean(
    "    'a'     ") == "a"
assert clean(" a ") == "a"
assert clean(" 'a' ") == "a"
assert clean(
    "test\r\n") == "test"
assert clean(
    "test\n\n\n") == "test"
assert clean("a") == "a"
assert clean(
    "test\t\t") == "test"
assert clean(
    "test'") == "test"
assert clean("") == ""
assert clean(
    "test\t\t\t") == "test"
assert clean(
    " test ") == "test"
