def oauth_generator(function, *args, **kwargs):
    """Set the _use_oauth keyword argument to True when appropriate.

    This is needed because generator functions may be called at anytime, and
    PRAW relies on the Reddit._use_oauth value at original call time to know
    when to make OAuth requests.

    Returned data is not modified.

    """
    if getattr(args[0], '_use_oauth', False):
        kwargs['_use_oauth'] = True
    return function(*args, **kwargs)

assert oauth_generator(lambda x: x, 1) == 1
assert oauth_generator(lambda x, y: 42, 42, 43) == 42
assert oauth_generator(lambda x, y, z: 42, 42, 43, 44) == 42
assert oauth_generator(lambda a, b, c, d, e, f, g, h, i: [a, b, c, d, e, f, g, h, i], 1, 2, 3, 4, 5, 6, 7, 8, 9) == [1, 2, 3, 4, 5, 6, 7, 8, 9]
assert oauth_generator(lambda s: s.split(), "a b c") == ['a', 'b', 'c']
assert oauth_generator(lambda a, b, _use_oauth=False: [a, b], 1, 2) == [1, 2]
assert oauth_generator(lambda a, b, _use_oauth=True: [a, b], 1, 2) == [1, 2]
assert oauth_generator(lambda a, b: [a, b], 1, 2) == [1, 2]
assert oauth_generator(lambda x, y, z, a, b=4, *c: (x, y, z, a, b, c), 1, 2, 3, 4) == (1, 2, 3, 4, 4, ())
assert oauth_generator(lambda x, y, _use_oauth=True: x + y, 1, 2) == 3
assert oauth_generator(lambda x, y, z, a: (x, y, z, a), 1, 2, 3, 4) == (1, 2, 3, 4)
assert oauth_generator(list, []) == []
assert oauth_generator(lambda x: x, None) == None
assert oauth_generator(lambda x: x, "test") == "test"
assert oauth_generator(lambda x: 42, 42) == 42
assert oauth_generator(lambda x: x, 2) == 2
assert oauth_generator(lambda x, y, _use_oauth=False: x + y, 1, 2) == 3
assert oauth_generator(lambda *args: args, 1, 2, 3) == (1, 2, 3)
assert oauth_generator(lambda x, y: x + y, 1, 2) == 3
assert oauth_generator(lambda x, y, z, a, b=4, **d: (x, y, z, a, b, d), 1, 2, 3, 4) == (1, 2, 3, 4, 4, {})
assert oauth_generator(lambda x, y, z, a, b=4, *c, **d: (x, y, z, a, b, c, d), 1, 2, 3, 4) == (1, 2, 3, 4, 4, (), {})
assert oauth_generator(lambda x, y: x + y, 2, 3) == 5
assert oauth_generator(lambda x: x, [None]) == [None]
assert oauth_generator(lambda x, y: y, "test", "test2") == "test2"
assert oauth_generator(lambda reddit, x: x, object(), 'foo') == 'foo'
assert oauth_generator(lambda x, y, z, a, b=4: (x, y, z, a, b), 1, 2, 3, 4) == (1, 2, 3, 4, 4)
