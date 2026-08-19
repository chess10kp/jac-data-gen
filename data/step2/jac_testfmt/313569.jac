"""Split a DEPS file entry into a URL and git sha."""
def _extract_url_and_sha_from_deps_entry(`entry: Any) -> object {
    assert (('url' in `entry) and ('rev' in `entry)) , (
        'Unexpected format: %s' % `entry
    );
    url = `entry['url'];
    sha = `entry['rev'];
    if url.endswith('.git') {
        url = url[:-len('.git')];
    }
    return (url, sha);
}

test "t0" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {
                'url': 'https://github.com/chromium/third_party/third_party.git',
                'rev': '12345'
            }
        ) == ('https://github.com/chromium/third_party/third_party', '12345')
    );;
}

test "t1" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {'url': 'https://example.org/repository/foo.git', 'rev': 'deadbeef'}
        ) == ('https://example.org/repository/foo', 'deadbeef')
    );;
}

test "t2" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {'url': 'https://chromium.googlesource.com/deps/url', 'rev': 'some sha'}
        ) == ('https://chromium.googlesource.com/deps/url', 'some sha')
    ) , 'https://chromium.googlesource.com/deps/url';;
}

test "t3" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {'url': 'https://example.org/repository/foo.git/bar', 'rev': 'deadbeef'}
        ) == ('https://example.org/repository/foo.git/bar', 'deadbeef')
    );;
}

test "t4" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {
                'url': 'https://chromium.googlesource.com/chromium/src.git',
                'rev': 'd3047f7b9e202798b1f718b5768613b4807109d9'
            }
        ) == (
            'https://chromium.googlesource.com/chromium/src',
            'd3047f7b9e202798b1f718b5768613b4807109d9'
        )
    );;
}

test "t5" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {'url': 'https://chromium.googlesource.com/foo/bar', 'rev': 'abcdef0'}
        ) == ('https://chromium.googlesource.com/foo/bar', 'abcdef0')
    );;
}

test "t6" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {'url': 'https://chromium.googlesource.com/v8/v8.git', 'rev': '7.1.219'}
        ) == ('https://chromium.googlesource.com/v8/v8', '7.1.219')
    );;
}

test "t7" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {'url': 'https://host/path/to/repo', 'rev': '123abc'}
        ) == ('https://host/path/to/repo', '123abc')
    );;
}

test "t8" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {'url': 'https://chromium.googlesource.com/v8/v8', 'rev': '7.1.219'}
        ) == ('https://chromium.googlesource.com/v8/v8', '7.1.219')
    );;
}

test "t9" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {
                'url': 'https://chromium.googlesource.com/foo/bar',
                'rev': 'abcdef0',
                'condition': 'checkout_mac'
            }
        ) == ('https://chromium.googlesource.com/foo/bar', 'abcdef0')
    );;
}

test "t10" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {
                'url': 'https://chromium.googlesource.com/chromium/src.git',
                'rev': '123456'
            }
        ) == ('https://chromium.googlesource.com/chromium/src', '123456')
    );;
}

test "t11" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {
                'url': 'https://example.com',
                'rev': 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef'
            }
        ) == ('https://example.com', 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef')
    );;
}

test "t12" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {'url': 'https://url.git', 'rev': 'sha1234567890abcdef'}
        ) == ('https://url', 'sha1234567890abcdef')
    );;
}

test "t13" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {
                'url': 'https://host/path/to/repo.git',
                'condition': 'mac',
                'rev': '123abc'
            }
        ) == ('https://host/path/to/repo', '123abc')
    );;
}

test "t14" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {
                'url': 'https://chromium.googlesource.com/chromium/src',
                'rev': '1234567890abcdef'
            }
        ) == ('https://chromium.googlesource.com/chromium/src', '1234567890abcdef')
    );;
}

test "t15" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {
                'url': 'https://chromium.googlesource.com/v8/v8.git',
                'rev': 'd8b165157787157682e70e5260c4639888b7c19b'
            }
        ) == (
            'https://chromium.googlesource.com/v8/v8',
            'd8b165157787157682e70e5260c4639888b7c19b'
        )
    );;
}

test "t16" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {'url': 'https://example.org/repository/foo', 'rev': 'deadbeef/beef'}
        ) == ('https://example.org/repository/foo', 'deadbeef/beef')
    );;
}

test "t17" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {'url': 'https://url.git', 'rev': 'rev'}
        ) == ('https://url', 'rev')
    );;
}

test "t18" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {
                'url': 'https://chromium.googlesource.com/v8/v8.git',
                'rev': '4f94e897724454c1577a9b60c6052743693a559b3'
            }
        ) == (
            'https://chromium.googlesource.com/v8/v8',
            '4f94e897724454c1577a9b60c6052743693a559b3'
        )
    );;
}

test "t19" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {'url': 'https://example.org/repository/foo', 'rev': 'deadbeef'}
        ) == ('https://example.org/repository/foo', 'deadbeef')
    );;
}

test "t20" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {'url': 'https://url.git', 'rev': 'sha1'}
        ) == ('https://url', 'sha1')
    );;
}

test "t21" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {
                'url': 'https://chromium.googlesource.com/chromium/src.git',
                'rev': 'abcdef'
            }
        ) == ('https://chromium.googlesource.com/chromium/src', 'abcdef')
    );;
}

test "t22" {
    assert (
        _extract_url_and_sha_from_deps_entry({'url': 'https://url', 'rev': 'rev'}) == (
            'https://url',
            'rev'
        )
    );;
}

test "t23" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {'url': 'https://host/path/to/repo.git', 'rev': '123abc'}
        ) == ('https://host/path/to/repo', '123abc')
    );;
}

test "t24" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {'url': 'https://chromium.googlesource.com/foo/bar.git', 'rev': 'abcdef0'}
        ) == ('https://chromium.googlesource.com/foo/bar', 'abcdef0')
    );;
}

test "t25" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {'url': 'https://chromium.googlesource.com/chromium/src', 'rev': 'abcdef'}
        ) == ('https://chromium.googlesource.com/chromium/src', 'abcdef')
    );;
}

test "t26" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {
                'url': 'https://example.com',
                'rev': 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef',
                'condition': 'some condition'
            }
        ) == ('https://example.com', 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef')
    );;
}

test "t27" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {'url': 'https://github.com/foo/bar', 'rev': 'abc123'}
        ) == ('https://github.com/foo/bar', 'abc123')
    );;
}

test "t28" {
    assert (
        _extract_url_and_sha_from_deps_entry({'url': 'https://url', 'rev': 'sha1'}) == (
            'https://url',
            'sha1'
        )
    );;
}

test "t29" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {
                'url': 'https://chromium.googlesource.com/foo/bar',
                'rev': 'abcdef0',
                'condition': 'checkout_win'
            }
        ) == ('https://chromium.googlesource.com/foo/bar', 'abcdef0')
    );;
}

test "t30" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {'url': 'https://url', 'rev': 'sha1234567890abcdef'}
        ) == ('https://url', 'sha1234567890abcdef')
    );;
}

test "t31" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {
                'url': 'https://chromium.googlesource.com/v8/v8',
                'rev': '7.1.219',
                'condition': 'checkout_mac'
            }
        ) == ('https://chromium.googlesource.com/v8/v8', '7.1.219')
    );;
}

test "t32" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {
                'url': 'https://skia.googlesource.com/angle/angle',
                'rev': '8e3e0b5f97451281728462d2a93f1f9b848d0711'
            }
        ) == (
            'https://skia.googlesource.com/angle/angle',
            '8e3e0b5f97451281728462d2a93f1f9b848d0711'
        )
    );;
}

test "t33" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {
                'url': 'https://skia.googlesource.com/angle/angle.git',
                'rev': '8e3e0b5f97451281728462d2a93f1f9b848d0711'
            }
        ) == (
            'https://skia.googlesource.com/angle/angle',
            '8e3e0b5f97451281728462d2a93f1f9b848d0711'
        )
    );;
}

test "t34" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {
                'url': 'https://host/path/to/repo.git',
                'rev': '123abc',
                'condition': 'mac'
            }
        ) == ('https://host/path/to/repo', '123abc')
    );;
}

test "t35" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {'url': 'https://chromium.googlesource.com/chromium/src', 'rev': '123456'}
        ) == ('https://chromium.googlesource.com/chromium/src', '123456')
    );;
}

test "t36" {
    assert (
        _extract_url_and_sha_from_deps_entry(
            {
                'url': 'https://chromium.googlesource.com/foo/bar.git',
                'rev': 'abcdef0',
                'condition': 'checkout_mac'
            }
        ) == ('https://chromium.googlesource.com/foo/bar', 'abcdef0')
    );;
}
