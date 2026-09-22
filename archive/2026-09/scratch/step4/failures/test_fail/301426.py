def wsgi_to_bytes(s):
    """Convert a native string to a WSGI / HTTP compatible byte string."""
    # Taken from PEP3333
    return s.encode("iso-8859-1")

assert wsgi_to_bytes("a") == b"a"
assert wsgi_to_bytes("\x00\x01\xff") == b"\x00\x01\xff"
assert wsgi_to_bytes("abcäöü") == b"abc\xe4\xf6\xfc"
assert wsgi_to_bytes("more_unicode") == b"more_unicode"
assert wsgi_to_bytes("abc\xff") == b"abc\xff"
assert wsgi_to_bytes("£") == wsgi_to_bytes("£")
assert wsgi_to_bytes("£") == b"\xa3"
assert wsgi_to_bytes("abc\N{LATIN SMALL LETTER A WITH DIAERESIS}") == \
        b"abc\xe4"
assert wsgi_to_bytes("hello") == b"hello"
assert wsgi_to_bytes("abc\xe4") == b"abc\xe4"
assert wsgi_to_bytes("") == b""
assert wsgi_to_bytes("\x7f") == b"\x7f"
assert wsgi_to_bytes("foobar") == b"foobar"
assert wsgi_to_bytes("foo") == b"foo"
assert wsgi_to_bytes("\xe4") == b"\xe4"
assert wsgi_to_bytes("£") == wsgi_to_bytes("£")
assert wsgi_to_bytes("a") == b"a"
assert wsgi_to_bytes("abc") == b"abc"
assert wsgi_to_bytes("\N{LATIN SMALL LETTER A WITH DIAERESIS}") == \
        b"\xe4"
assert wsgi_to_bytes("foo") == b"foo"
assert wsgi_to_bytes("\xff\x00") == b"\xff\x00"
assert wsgi_to_bytes("test") == b"test"
assert wsgi_to_bytes("£") == b"\xa3"
assert wsgi_to_bytes("hello") == b"hello"
assert wsgi_to_bytes("Hello, World!") == b"Hello, World!"
assert wsgi_to_bytes("test") == b"test"
assert wsgi_to_bytes("Hello, World!\xe9") == b"Hello, World!\xe9"
assert wsgi_to_bytes('foo') == b'foo'
assert wsgi_to_bytes("abc") == b"abc"
assert wsgi_to_bytes("abc\xff") == b"abc\xff"
assert wsgi_to_bytes("\n") == b"\n"
assert wsgi_to_bytes("\n") == b"\n"
assert wsgi_to_bytes("\xe2\x82\xac\xe2\x82\xac\xe2\x82\xac") == b"\xe2\x82\xac\xe2\x82\xac\xe2\x82\xac"
assert wsgi_to_bytes("£") == "£".encode("iso-8859-1")
assert wsgi_to_bytes("abcd") == b"abcd"
assert wsgi_to_bytes("\xff") == b"\xff"
assert wsgi_to_bytes("\xff") == b"\xff"
assert wsgi_to_bytes("\x00") == b"\x00"
assert wsgi_to_bytes("\x01\x02\x03") == b"\x01\x02\x03"
assert wsgi_to_bytes("") == b""
assert wsgi_to_bytes("£") == "£".encode("iso-8859-1")
assert wsgi_to_bytes("unicode") == b"unicode"
assert wsgi_to_bytes("\x00\xff") == b"\x00\xff"
assert wsgi_to_bytes("abcd") == b"abcd"
assert wsgi_to_bytes("\x00\x01") == b"\x00\x01"
