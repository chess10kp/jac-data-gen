def resolve_uri(uri):
    """
    Resolves uri if it's not absolute

    :param uri: str uri
    :return: str url
    """
    if not(uri.startswith('http://') or uri.startswith('https://')):
        return '127.0.0.1%s' % uri
    else:
        return uri

assert resolve_uri('http://localhost') == 'http://localhost'
assert resolve_uri('') == '127.0.0.1'
assert resolve_uri('/foo') == '127.0.0.1/foo'
assert resolve_uri('www.google.com') == '127.0.0.1%s' % 'www.google.com'
assert resolve_uri('/') == '127.0.0.1/'
assert resolve_uri('http://127.0.0.1/foo') == 'http://127.0.0.1/foo'
assert resolve_uri('http://example.com/whatever') == 'http://example.com/whatever'
assert resolve_uri('http://google.com:80') == 'http://google.com:80'
assert resolve_uri('http://127.0.0.1/foo/') == 'http://127.0.0.1/foo/'
assert resolve_uri(
    'https://www.example.com'
) == 'https://www.example.com'
assert resolve_uri('example.com/subpath') == '127.0.0.1example.com/subpath'
assert resolve_uri('http://127.0.0.1/') == 'http://127.0.0.1/'
assert resolve_uri(
    'https://www.example.com/page/1'
) == 'https://www.example.com/page/1'
assert resolve_uri('http://127.0.0.1') == 'http://127.0.0.1'
assert resolve_uri(
    '/page/1'
) == '127.0.0.1/page/1'
assert resolve_uri(
    '//www.example.com/page/1'
) == '127.0.0.1//www.example.com/page/1'
assert resolve_uri('example.com') == '127.0.0.1example.com'
assert resolve_uri('https://www.google.com/about') == 'https://www.google.com/about'
assert resolve_uri('http://localhost/') == 'http://localhost/'
assert resolve_uri('/example.com') == '127.0.0.1/example.com'
assert resolve_uri('/whatever') == '127.0.0.1/whatever'
assert resolve_uri('test') == '127.0.0.1test'
assert resolve_uri('whatever') == '127.0.0.1whatever'
assert resolve_uri('https://www.google.com') == 'https://www.google.com'
assert resolve_uri('http://google.com/test') == 'http://google.com/test'
assert resolve_uri(
    '//www.example.com'
) == '127.0.0.1//www.example.com'
assert resolve_uri('/hello/world') == '127.0.0.1/hello/world'
assert resolve_uri('http://www.google.com:80') == 'http://www.google.com:80'
assert resolve_uri('http://127.0.0.1:8000/foo') == 'http://127.0.0.1:8000/foo'
assert resolve_uri('google.com') == '127.0.0.1%s' % 'google.com'
assert resolve_uri('http://www.google.com') == 'http://www.google.com'
assert resolve_uri('http://localhost/foo') == 'http://localhost/foo'
assert resolve_uri('https://example.com') == 'https://example.com'
assert resolve_uri('http://127.0.0.1:8080/') == 'http://127.0.0.1:8080/'
assert resolve_uri('//whatever') == '127.0.0.1//whatever'
assert resolve_uri('http://example.com') == 'http://example.com'
assert resolve_uri('https://127.0.0.1') == 'https://127.0.0.1'
assert resolve_uri('google.com:80') == '127.0.0.1%s' % 'google.com:80'
assert resolve_uri('http://127.0.0.1:8080') == 'http://127.0.0.1:8080'
assert resolve_uri('https://example.com/whatever') == 'https://example.com/whatever'
assert resolve_uri(
    'http://www.example.com/page/1'
) == 'http://www.example.com/page/1'
