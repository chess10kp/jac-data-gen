"""Encode request (command, *args) to redis bulk bytes.

Note that command is a string defined by redis.
All elements in args should be a string.
"""
def encode(request: tuple[str, ...]) -> str {
    assert isinstance(request, tuple);
    return ('*%d\r\n' % len(request)) + ''.join(['$%d\r\n%s\r\n' % (len(str(x)), x) for x in request]);
}