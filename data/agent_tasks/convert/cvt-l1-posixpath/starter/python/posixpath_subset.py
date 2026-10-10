"""Common operations on Posix pathnames (pure string subset).

Trimmed from CPython v3.12.7 Lib/posixpath.py + Lib/genericpath.py (PSF-2.0):
only the purely lexical str functions are kept (no filesystem access, no bytes,
no os.fspath); genericpath.commonprefix and _splitext are inlined.
"""

curdir = '.'
pardir = '..'
extsep = '.'
sep = '/'

__all__ = ["isabs", "join", "split", "splitext", "splitroot", "basename",
           "dirname", "normpath", "commonprefix", "commonpath"]


# Return whether a path is absolute.
def isabs(s):
    """Test whether a path is absolute"""
    return s.startswith(sep)


# Join pathnames.
# Ignore the previous parts if a part is absolute.
# Insert a '/' unless the first part is empty or already ends in '/'.
def join(a, *p):
    """Join two or more pathname components, inserting '/' as needed.
    If any component is an absolute path, all previous path components
    will be discarded.  An empty last part will result in a path that
    ends with a separator."""
    path = a
    for b in p:
        if b.startswith(sep):
            path = b
        elif not path or path.endswith(sep):
            path += b
        else:
            path += sep + b
    return path


# Split a path in head (everything up to the last '/') and tail (the
# rest).  If the path ends in '/', tail will be empty.  If there is no
# '/' in the path, head  will be empty.
# Trailing '/'es are stripped from head unless it is the root.
def split(p):
    """Split a pathname.  Returns tuple "(head, tail)" where "tail" is
    everything after the final slash.  Either part may be empty."""
    i = p.rfind(sep) + 1
    head, tail = p[:i], p[i:]
    if head and head != sep*len(head):
        head = head.rstrip(sep)
    return head, tail


def splitext(p):
    """Split the extension from a pathname.

    Extension is everything from the last dot to the end, ignoring
    leading dots.  Returns "(root, ext)"; ext may be empty."""
    sepIndex = p.rfind(sep)
    dotIndex = p.rfind(extsep)
    if dotIndex > sepIndex:
        # skip all leading dots
        filenameIndex = sepIndex + 1
        while filenameIndex < dotIndex:
            if p[filenameIndex:filenameIndex+1] != extsep:
                return p[:dotIndex], p[dotIndex:]
            filenameIndex += 1
    return p, p[:0]


def splitroot(p):
    """Split a pathname into drive, root and tail. On Posix, drive is always
    empty; the root may be empty, a single slash, or two slashes. The tail
    contains anything after the root. For example:

        splitroot('foo/bar') == ('', '', 'foo/bar')
        splitroot('/foo/bar') == ('', '/', 'foo/bar')
        splitroot('//foo/bar') == ('', '//', 'foo/bar')
        splitroot('///foo/bar') == ('', '/', '//foo/bar')
    """
    empty = ''
    if p[:1] != sep:
        # Relative path, e.g.: 'foo'
        return empty, empty, p
    elif p[1:2] != sep or p[2:3] == sep:
        # Absolute path, e.g.: '/foo', '///foo', '////foo', etc.
        return empty, sep, p[1:]
    else:
        # Precisely two leading slashes, e.g.: '//foo'. Implementation defined per POSIX
        return empty, p[:2], p[2:]


def basename(p):
    """Returns the final component of a pathname"""
    i = p.rfind(sep) + 1
    return p[i:]


def dirname(p):
    """Returns the directory component of a pathname"""
    i = p.rfind(sep) + 1
    head = p[:i]
    if head and head != sep*len(head):
        head = head.rstrip(sep)
    return head


def normpath(path):
    """Normalize path, eliminating double slashes, etc."""
    empty = ''
    dot = '.'
    dotdot = '..'
    if path == empty:
        return dot
    _, initial_slashes, path = splitroot(path)
    comps = path.split(sep)
    new_comps = []
    for comp in comps:
        if comp in (empty, dot):
            continue
        if (comp != dotdot or (not initial_slashes and not new_comps) or
             (new_comps and new_comps[-1] == dotdot)):
            new_comps.append(comp)
        elif new_comps:
            new_comps.pop()
    comps = new_comps
    path = initial_slashes + sep.join(comps)
    return path or dot


def commonprefix(m):
    "Given a list of pathnames, returns the longest common leading component"
    if not m: return ''
    s1 = min(m)
    s2 = max(m)
    for i, c in enumerate(s1):
        if c != s2[i]:
            return s1[:i]
    return s1


# Return the longest common sub-path of the sequence of paths given as input.
# The paths are not normalized before comparing them (this is the
# responsibility of the caller). Any trailing separator is stripped from the
# returned path.
def commonpath(paths):
    """Given a sequence of path names, returns the longest common sub-path."""
    if not paths:
        raise ValueError('commonpath() arg is an empty sequence')
    split_paths = [path.split(sep) for path in paths]
    try:
        isabs, = set(p[:1] == sep for p in paths)
    except ValueError:
        raise ValueError("Can't mix absolute and relative paths") from None
    split_paths = [[c for c in s if c and c != curdir] for s in split_paths]
    s1 = min(split_paths)
    s2 = max(split_paths)
    common = s1
    for i, c in enumerate(s1):
        if c != s2[i]:
            common = s1[:i]
            break
    prefix = sep if isabs else sep[:0]
    return prefix + sep.join(common)
