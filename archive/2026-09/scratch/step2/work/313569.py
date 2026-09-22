def _extract_url_and_sha_from_deps_entry(entry):
  """Split a DEPS file entry into a URL and git sha."""
  assert 'url' in entry and 'rev' in entry, 'Unexpected format: %s' % entry
  url = entry['url']
  sha = entry['rev']

  # Strip unnecessary ".git" from the URL where applicable.
  if url.endswith('.git'):
    url = url[:-len('.git')]

  return url, sha

assert _extract_url_and_sha_from_deps_entry(
    {'url': 'https://github.com/chromium/third_party/third_party.git','rev': '12345'}) == (
        'https://github.com/chromium/third_party/third_party',
        '12345',
    )
assert _extract_url_and_sha_from_deps_entry(
    {'url': 'https://example.org/repository/foo.git','rev': 'deadbeef'}) == (
    'https://example.org/repository/foo', 'deadbeef')
assert _extract_url_and_sha_from_deps_entry(
    {'url': 'https://chromium.googlesource.com/deps/url','rev':'some sha'}) == (
        'https://chromium.googlesource.com/deps/url','some sha'), 'https://chromium.googlesource.com/deps/url'
assert _extract_url_and_sha_from_deps_entry(
    {'url': 'https://example.org/repository/foo.git/bar','rev': 'deadbeef'}) == (
    'https://example.org/repository/foo.git/bar', 'deadbeef')
assert _extract_url_and_sha_from_deps_entry(
  {'url': 'https://chromium.googlesource.com/chromium/src.git','rev': 'd3047f7b9e202798b1f718b5768613b4807109d9'}) == \
  ('https://chromium.googlesource.com/chromium/src', 'd3047f7b9e202798b1f718b5768613b4807109d9')
assert _extract_url_and_sha_from_deps_entry(
  {'url': 'https://chromium.googlesource.com/foo/bar','rev': 'abcdef0'}) == ('https://chromium.googlesource.com/foo/bar', 'abcdef0')
assert _extract_url_and_sha_from_deps_entry(
    {'url': 'https://chromium.googlesource.com/v8/v8.git','rev': '7.1.219'}) == (
        'https://chromium.googlesource.com/v8/v8',
        '7.1.219')
assert _extract_url_and_sha_from_deps_entry(
    {'url': 'https://host/path/to/repo','rev': '123abc'}
) == ('https://host/path/to/repo', '123abc')
assert _extract_url_and_sha_from_deps_entry(
    {'url': 'https://chromium.googlesource.com/v8/v8','rev': '7.1.219'}) == (
        'https://chromium.googlesource.com/v8/v8',
        '7.1.219')
assert _extract_url_and_sha_from_deps_entry(
  {'url': 'https://chromium.googlesource.com/foo/bar','rev': 'abcdef0', 'condition': 'checkout_mac'}) == ('https://chromium.googlesource.com/foo/bar', 'abcdef0')
assert _extract_url_and_sha_from_deps_entry(
    {'url': 'https://chromium.googlesource.com/chromium/src.git','rev': '123456'}) == (
        'https://chromium.googlesource.com/chromium/src',
        '123456',
    )
assert _extract_url_and_sha_from_deps_entry(
  {
    'url': 'https://example.com',
   'rev': 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef',
  }) == ('https://example.com', 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef')
assert _extract_url_and_sha_from_deps_entry(
    {'url': 'https://url.git','rev':'sha1234567890abcdef'}) == ('https://url','sha1234567890abcdef')
assert _extract_url_and_sha_from_deps_entry(
    {'url': 'https://host/path/to/repo.git', 'condition':'mac','rev': '123abc'}
) == ('https://host/path/to/repo', '123abc')
assert _extract_url_and_sha_from_deps_entry(
  {'url': 'https://chromium.googlesource.com/chromium/src','rev': '1234567890abcdef'}) == \
  ('https://chromium.googlesource.com/chromium/src', '1234567890abcdef')
assert _extract_url_and_sha_from_deps_entry(
  {'url': 'https://chromium.googlesource.com/v8/v8.git',
  'rev': 'd8b165157787157682e70e5260c4639888b7c19b'}) == (
      'https://chromium.googlesource.com/v8/v8',
      'd8b165157787157682e70e5260c4639888b7c19b')
assert _extract_url_and_sha_from_deps_entry(
    {'url': 'https://example.org/repository/foo','rev': 'deadbeef/beef'}) == (
    'https://example.org/repository/foo', 'deadbeef/beef')
assert _extract_url_and_sha_from_deps_entry(
    {'url': 'https://url.git','rev':'rev'}) == ('https://url','rev')
assert _extract_url_and_sha_from_deps_entry(
    {'url': 'https://chromium.googlesource.com/v8/v8.git','rev': '4f94e897724454c1577a9b60c6052743693a559b3'}) == (
        'https://chromium.googlesource.com/v8/v8',
        '4f94e897724454c1577a9b60c6052743693a559b3')
assert _extract_url_and_sha_from_deps_entry(
    {'url': 'https://example.org/repository/foo','rev': 'deadbeef'}) == (
    'https://example.org/repository/foo', 'deadbeef')
assert _extract_url_and_sha_from_deps_entry(
    {'url': 'https://url.git','rev':'sha1'}) == ('https://url','sha1')
assert _extract_url_and_sha_from_deps_entry(
    {'url': 'https://chromium.googlesource.com/chromium/src.git','rev': 'abcdef'}) == (
        'https://chromium.googlesource.com/chromium/src',
        'abcdef',
    )
assert _extract_url_and_sha_from_deps_entry(
    {'url': 'https://url','rev':'rev'}) == ('https://url','rev')
assert _extract_url_and_sha_from_deps_entry(
    {'url': 'https://host/path/to/repo.git','rev': '123abc'}
) == ('https://host/path/to/repo', '123abc')
assert _extract_url_and_sha_from_deps_entry(
  {'url': 'https://chromium.googlesource.com/foo/bar.git','rev': 'abcdef0'}) == ('https://chromium.googlesource.com/foo/bar', 'abcdef0')
assert _extract_url_and_sha_from_deps_entry(
    {'url': 'https://chromium.googlesource.com/chromium/src','rev': 'abcdef'}) == (
        'https://chromium.googlesource.com/chromium/src',
        'abcdef',
    )
assert _extract_url_and_sha_from_deps_entry(
  {
    'url': 'https://example.com',
   'rev': 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef',
    'condition':'some condition',
  }) == ('https://example.com', 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef')
assert _extract_url_and_sha_from_deps_entry(
  {'url': 'https://github.com/foo/bar','rev': 'abc123'}) == ('https://github.com/foo/bar', 'abc123')
assert _extract_url_and_sha_from_deps_entry(
    {'url': 'https://url','rev':'sha1'}) == ('https://url','sha1')
assert _extract_url_and_sha_from_deps_entry(
  {'url': 'https://chromium.googlesource.com/foo/bar','rev': 'abcdef0', 'condition': 'checkout_win'}) == ('https://chromium.googlesource.com/foo/bar', 'abcdef0')
assert _extract_url_and_sha_from_deps_entry(
    {'url': 'https://url','rev':'sha1234567890abcdef'}) == ('https://url','sha1234567890abcdef')
assert _extract_url_and_sha_from_deps_entry(
    {'url': 'https://chromium.googlesource.com/v8/v8','rev': '7.1.219', 'condition': 'checkout_mac'}) == (
        'https://chromium.googlesource.com/v8/v8',
        '7.1.219')
assert _extract_url_and_sha_from_deps_entry(
  {'url': 'https://skia.googlesource.com/angle/angle','rev': '8e3e0b5f97451281728462d2a93f1f9b848d0711'}) == (
    'https://skia.googlesource.com/angle/angle', '8e3e0b5f97451281728462d2a93f1f9b848d0711')
assert _extract_url_and_sha_from_deps_entry(
  {'url': 'https://skia.googlesource.com/angle/angle.git','rev': '8e3e0b5f97451281728462d2a93f1f9b848d0711'}) == (
    'https://skia.googlesource.com/angle/angle', '8e3e0b5f97451281728462d2a93f1f9b848d0711')
assert _extract_url_and_sha_from_deps_entry(
    {'url': 'https://host/path/to/repo.git','rev': '123abc', 'condition':'mac'}
) == ('https://host/path/to/repo', '123abc')
assert _extract_url_and_sha_from_deps_entry(
    {'url': 'https://chromium.googlesource.com/chromium/src','rev': '123456'}) == (
        'https://chromium.googlesource.com/chromium/src',
        '123456',
    )
assert _extract_url_and_sha_from_deps_entry(
  {'url': 'https://chromium.googlesource.com/foo/bar.git','rev': 'abcdef0', 'condition': 'checkout_mac'}) == ('https://chromium.googlesource.com/foo/bar', 'abcdef0')
