"""
    Return a boolean indicating whether the given status name is frozen or not.

    @type status: C{unicode}
    @rtype: C{bool}
    """
def isFrozen(status: Any) -> object {
    return status.startswith('.');
}
with entry {
    assert (isFrozen('foo bar') == False);
    assert (isFrozen("") == False);
    assert (isFrozen('foo.bar..') == False);
    assert (isFrozen('.foo.') == True);
    assert (isFrozen("foo.bar.baz") == False);
    assert (isFrozen('') == False);
    assert (isFrozen("foo.bar") == False);
    assert (isFrozen('foo.bar....') == False);
    assert (isFrozen(".foo") == True);
    assert (isFrozen('.foo bar baz') == True);
    assert (isFrozen('a..') == False);
    assert (isFrozen('.abc') == True);
    assert (isFrozen('frozen') == False);
    assert (isFrozen(".foo") == True);
    assert (isFrozen('zA') == False);
    assert (isFrozen('.foo') == True);
    assert (isFrozen('A') == False);
    assert (isFrozen("foo.bar.baz") == False);
    assert (isFrozen('foo.bar.') == False);
    assert (isFrozen(".foo.bar.baz") == True);
    assert (isFrozen("foo") == False);
    assert (isFrozen(".foo.bar") == True);
    assert (isFrozen("foo.bar") == False);
    assert (isFrozen('foo bar baz') == False);
    assert (isFrozen("foo.bar.baz.quux") == False);
    assert (isFrozen('.foo.bar.baz.quux') == True);
    assert (isFrozen("foo") == False);
    assert (isFrozen('.X') == True);
    assert (isFrozen('.Y') == True);
    assert (isFrozen('foo.bar.baz') == False);
    assert (isFrozen('.foo.bar') == True);
    assert (isFrozen('foo.bar.baz.quux') == False);
    assert (isFrozen('bzr') == False);
    assert (isFrozen(' ') == False);
    assert (isFrozen('.frozen') == True);
    assert (isFrozen(".foo.bar.baz.quux") == True);
    assert (isFrozen('.M') == True);
    assert (isFrozen('.') == True);
    assert (isFrozen('a') == False);
    assert (isFrozen('foo..bar') == False);
    assert (isFrozen('foo') == False);
    assert (isFrozen('.foo bar') == True);
    assert (isFrozen('. ') == True);
    assert (isFrozen('.first') == True);
    assert (isFrozen('.foo.bar.baz') == True);
    assert (isFrozen('unfrozen') == False);
    assert (isFrozen('..foo') == True);
    assert (isFrozen('..foo.bar') == True);
    assert (isFrozen('abc') == False);
    assert (isFrozen('.Z') == True);
    assert (isFrozen('first') == False);
    assert (isFrozen('foo..bar.') == False);
    assert (isFrozen('foo.bar') == False);
}

