def __parse_request_range(range_header_text):
    """ Return a tuple describing the byte range requested in a GET request
    If the range is open ended on the left or right side, then a value of None
    will be set.
    RFC7233: http://svn.tools.ietf.org/svn/wg/httpbis/specs/rfc7233.html#header.range
    Examples:
      Range : bytes=1024-
      Range : bytes=10-20
      Range : bytes=-999
    """

    left = None
    right = None

    if not range_header_text:
        return left, right

    range_header_text = range_header_text.strip()
    if not range_header_text.startswith('bytes'):
        return left, right

    components = range_header_text.split("=")
    if len(components) != 2:
        return left, right

    components = components[1].split("-")

    try:
        right = int(components[1])
    except:
        pass

    try:
        left = int(components[0])
    except:
        pass

    return left, right

assert __parse_request_range('bytes=10-') == (10, None)
assert __parse_request_range("bytes=10-") == (10, None)
assert __parse_request_range("Not bytes=10-20") == (None, None)
assert __parse_request_range("bytes=-100") == (None, 100)
assert __parse_request_range("bytes=1024") == (1024, None)
assert __parse_request_range("bytes=1024-") == (1024, None)
assert __parse_request_range("bytes=-20") == (None, 20)
assert __parse_request_range('bytes=abc1024') == (None, None)
assert __parse_request_range("bytes=-1024") == (None, 1024)
assert __parse_request_range("bytes=a-") == (None, None)
assert __parse_request_range("bytes=foo-") == (None, None)
assert __parse_request_range('bytes=-5') == (None, 5)
assert __parse_request_range("bytes=-1024-") == (None, 1024)
assert __parse_request_range("bytes=100-") == (100, None)
assert __parse_request_range('bytes=1024-') == (1024, None)
assert __parse_request_range("bytes=--") == (None, None)
assert __parse_request_range("bytes=-") == (None, None)
assert __parse_request_range("bytes=-10") == (None, 10)
assert __parse_request_range('bytes=-1a') == (None, None)
assert __parse_request_range('bytes=-2') == (None, 2)
assert __parse_request_range('bytes=5-') == (5, None)
assert __parse_request_range("bytes=10-20-") == (10, 20)
assert __parse_request_range('bytes=-1') == (None, 1)
assert __parse_request_range("bytes=1-1") == (1, 1)
assert __parse_request_range('bytes=10-20') == (10, 20)
assert __parse_request_range("bytes=") == (None, None)
assert __parse_request_range('bytes=1a') == (None, None)
assert __parse_request_range('bytes=a-') == (None, None)
assert __parse_request_range('bytes=-1024') == (None, 1024)
assert __parse_request_range("") == (None, None)
assert __parse_request_range("bytes=1024-1234-") == (1024, 1234)
assert __parse_request_range("bytes=10-20 30") == (10, None)
assert __parse_request_range("\t") == (None, None)
assert __parse_request_range('') == (None, None)
assert __parse_request_range("bytes=1024-1024") == (1024, 1024)
assert __parse_request_range('bytes=0-') == (0, None)
assert __parse_request_range('bytes=0') == (0, None)
assert __parse_request_range("bytes=a-b") == (None, None)
assert __parse_request_range("bytes=-1024-1234-") == (None, 1024)
assert __parse_request_range("bytes=hello") == (None, None)
assert __parse_request_range("bytes=-9990-") == (None, 9990)
assert __parse_request_range("bytes=1-") == (1, None)
assert __parse_request_range('bytes=-') == (None, None)
assert __parse_request_range('bytes=0-10') == (0, 10)
assert __parse_request_range("bytes=bad") == (None, None)
assert __parse_request_range("bytes=-B") == (None, None)
assert __parse_request_range("bytes=-10-20-") == (None, 10)
assert __parse_request_range('bytes=10-20 ') == (10, 20)
assert __parse_request_range("bytes=a") == (None, None)
assert __parse_request_range(" ") == (None, None)
assert __parse_request_range("bytes=-2") == (None, 2)
assert __parse_request_range("A=10-20") == (None, None)
assert __parse_request_range("bytes=1024-2048") == (1024, 2048)
assert __parse_request_range("bytes= ") == (None, None)
assert __parse_request_range("bytes=-bar") == (None, None)
assert __parse_request_range("  ") == (None, None)
assert __parse_request_range("bytes=-hello") == (None, None)
assert __parse_request_range("bytes=-1024-1234") == (None, 1024)
assert __parse_request_range('bytes=1-') == (1, None)
assert __parse_request_range("bytes=-2048") == (None, 2048)
assert __parse_request_range('bytes=1-2') == (1, 2)
assert __parse_request_range("bytes=10-999") == (10, 999)
assert __parse_request_range("bytes=foo") == (None, None)
assert __parse_request_range("bytes=100-200") == (100, 200)
assert __parse_request_range("bytes") == (None, None)
assert __parse_request_range("bytes=-b") == (None, None)
assert __parse_request_range("1024-") == (None, None)
assert __parse_request_range('bytes=-999') == (None, 999)
assert __parse_request_range('bytes=0-5') == (0, 5)
assert __parse_request_range('bytes=-1000') == (None, 1000)
assert __parse_request_range(' bytes=1024- ') == (1024, None)
assert __parse_request_range(None) == (None, None)
assert __parse_request_range('bytes') == (None, None)
assert __parse_request_range(' ') == (None, None)
assert __parse_request_range("bytes=-999") == (None, 999)
assert __parse_request_range("bytes=20-10") == (20, 10)
assert __parse_request_range('bytes=') == (None, None)
assert __parse_request_range("bytes=10-20") == (10, 20)
assert __parse_request_range('bytes =') == (None, None)
assert __parse_request_range("bytes=0-1024") == (0, 1024)
assert __parse_request_range("bytes=2-") == (2, None)
assert __parse_request_range('bytes=-10') == (None, 10)
assert __parse_request_range("not a range") == (None, None)
assert __parse_request_range("bytes=-0") == (None, 0)
assert __parse_request_range("bytes=1024-1234") == (1024, 1234)
assert __parse_request_range("foo") == (None, None)
assert __parse_request_range("bytes=foo-bar") == (None, None)
assert __parse_request_range('bytes=a') == (None, None)
