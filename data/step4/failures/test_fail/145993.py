def transparent(value, function, *args, **kwargs):
    """
    Invoke ``function`` with ``value`` and other arguments, return ``value``.

    Use this to add a function to a callback chain without disrupting the
    value of the callback chain::

        d = defer.succeed(42)
        d.addCallback(transparent, print)
        d.addCallback(lambda x: x == 42)
    """
    function(value, *args, **kwargs)
    return value

assert transparent(42, print, 42, 24, 64, 256, 1024) == 42
assert transparent(42, lambda x: x) == 42
assert transparent(42, print, 42, 24, 64, 256, 1024, 4096) == 42
assert transparent(42, print, 42, 24, 64) == 42
assert transparent(1, lambda x, y: None, 2) == 1
assert transparent(1, print, "foo") == 1
assert transparent(1, lambda x: x) == 1
assert transparent(42, lambda value: value) == 42
assert transparent(1, lambda x, y=3: None, 2) == 1
assert transparent(1, lambda *x, **y: None, 2) == 1
assert transparent(1, print, 2) == 1
assert transparent(0, print, 1, 2, 3) == 0
assert transparent(1, lambda x, *y: None, 2) == 1
assert transparent(1, lambda v, v2: None, 1) == 1
assert transparent(1, lambda x, y: x, 1) == 1
assert transparent(1, lambda *args: args[0], 2) == 1
assert transparent(42, print, 42, 24) == 42
assert transparent(1, print, "foo", "bar") == 1
assert transparent(1, lambda v: None) == 1
assert transparent(1, lambda v, v2=2: None, 1) == 1
assert transparent(1, print, 1) == 1
assert transparent(1, lambda x=2, y=3: None) == 1
assert transparent(0, print, 1) == 0
assert transparent(1, lambda v: v) == 1
assert transparent(42, lambda x, y, z: x + y + z, 1, 2) == 42
assert transparent(1, lambda x, y=1: None, 2) == 1
assert transparent(0, print) == 0
assert transparent(1, lambda *args: args[0]) == 1
assert transparent(1, print, 2, 3) == 1
assert transparent(42, print) == 42
assert transparent(1, lambda x, **kwargs: None) == 1
assert transparent(42, lambda x: None) == 42
assert transparent(42, print, 42, 24, 64, 256) == 42
assert transparent(42, lambda x, y: None, 43) == 42
assert transparent(1, print, "one") == 1
assert transparent(42, print, 42) == 42
assert transparent(1, print) == 1
assert transparent(1, lambda x, y: x, 2) == 1
assert transparent(1, lambda x, **kwargs: x) == 1
assert transparent(1, lambda x, y=2: y) == 1
assert transparent(1, lambda v, v2=2: None) == 1
assert transparent(42, lambda x, **kwargs: x) == 42
assert transparent(1, print, 1, 2) == 1
assert transparent(1, lambda x, *args: x) == 1
assert transparent(1, lambda x: None) == 1
assert transparent(1, lambda x=2: x) == 1
assert transparent(1, lambda x=1: None) == 1
