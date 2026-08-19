def drop_key_safely(dictionary, key):
    """Drop a key from a dict if it exists and return that change"""
    if key in dictionary:
        del dictionary[key]
    return dictionary

assert drop_key_safely(dict(), "a") == dict()
assert drop_key_safely(
    {'a': 1, 'b': 2}, 'b') == {'a': 1}
assert drop_key_safely({"a": "a", "b": "b", "c": "c"}, "b") == {"a": "a", "c": "c"}
assert drop_key_safely(
    {'a': 1, 'b': 2},
    'a',
) == {
    'b': 2,
}
assert drop_key_safely({"a": "a", "b": "b"}, "b") == {"a": "a"}
assert drop_key_safely({}, "a") == {}
assert drop_key_safely({"a": "a"}, "a") == {}
assert drop_key_safely(
    {'a': 1, 'b': 2, 'c': 3},
    'c'
) == {'a': 1, 'b': 2}
assert drop_key_safely(
    {'A': 2, 'B': 3, 'C': 4}, 'C'
) == {'A': 2, 'B': 3}
assert drop_key_safely(
    {'a': 1, 'b': 2},
    'c',
) == {
    'a': 1,
    'b': 2,
}
assert drop_key_safely(
    {
        "a": 1,
        "b": 2
    },
    "b"
) == {
    "a": 1
}
assert drop_key_safely(
    {'a': 1},
    'd') == {'a': 1}
assert drop_key_safely(
    {},
    'a') == {}
assert drop_key_safely(
    {},
    'd') == {}
assert drop_key_safely(
    {'a': 1, 'b': 2},
    'b'
) == {'a': 1}
assert drop_key_safely(
    {
        "a": 1,
        "b": 2
    },
    "c"
) == {
    "a": 1,
    "b": 2
}
assert drop_key_safely(
    {'a': 1, 'b': 2, 'c': 3},
    'b') == {'a': 1, 'c': 3}
assert drop_key_safely(
    {
        "key1": "value1",
        "key2": "value2",
    },
    "key1",
) == {
    "key2": "value2",
}
assert drop_key_safely(
    {'a': 1, 'b': 2},
    'b',
) == {
    'a': 1,
}
assert drop_key_safely(
    {'a': 1, 'b': 2, 'c': 3},
    'd'
) == {'a': 1, 'b': 2, 'c': 3}
assert drop_key_safely(dict(), 'a') == dict()
assert drop_key_safely(
    {'a': 1, 'b': 2, 'c': 3},
    'b'
) == {'a': 1, 'c': 3}
assert drop_key_safely(
    {
        "key1": "value1",
        "key2": "value2",
    },
    "key2",
) == {
    "key1": "value1",
}
assert drop_key_safely({"a": "a"}, "b") == {"a": "a"}
assert drop_key_safely({"a": "a", "b": "b"}, "a") == {"b": "b"}
assert drop_key_safely({"date": 4}, "date") == {}
assert drop_key_safely({}, 'a') == dict()
assert drop_key_safely(
    {'a': 1},
    'a') == {}
assert drop_key_safely(
    {'a': 1, 'b': 2, 'c': 3},
    'a'
) == {'b': 2, 'c': 3}
assert drop_key_safely(
    {'a': 1, 'b': 2},
    'c'
) == {'a': 1, 'b': 2}
assert drop_key_safely(
    {'a': 1, 'b': 2, 'c': 3},
    'a') == {'b': 2, 'c': 3}
assert drop_key_safely(dict(), "b") == dict()
assert drop_key_safely(
    {'a': 1}, 'b') == {'a': 1}
assert drop_key_safely(dict(), "a") == drop_key_safely(dict(), "b")
assert drop_key_safely(
    {'A': 2, 'B': 3, 'C': 4}, 'D'
) == {'A': 2, 'B': 3, 'C': 4}
assert drop_key_safely(
    {"apple": 1, "banana": 2, "clementine": 3, "date": 4}, "date") == {"apple": 1, "banana": 2, "clementine": 3}
assert drop_key_safely(
    {'A': 2, 'B': 3, 'C': 4}, 'A'
) == {'B': 3, 'C': 4}
assert drop_key_safely(
    {
        "key1": "value1",
        "key2": "value2",
    },
    "key3",
) == {
    "key1": "value1",
    "key2": "value2",
}
assert drop_key_safely({"apple": 1, "banana": 2, "clementine": 3, "date": 4}, "date") == {"apple": 1, "banana": 2, "clementine": 3}
assert drop_key_safely(
    {'a': 1, 'b': 2, 'c': 3},
    'c') == {'a': 1, 'b': 2}
assert drop_key_safely(
    {'a': 1, 'b': 2, 'c': 3},
    'd') == {'a': 1, 'b': 2, 'c': 3}
assert drop_key_safely(
    {'a': 1, 'b': 2}, 'a') == {'b': 2}
assert drop_key_safely(
    {'a': 1, 'b': 2},
    'a'
) == {'b': 2}
assert drop_key_safely(
    {'a': 1, 'b': 2},
    'b') == {'a': 1}
assert drop_key_safely(
    {
        "a": 1,
        "b": 2
    },
    "a"
) == {
    "b": 2
}
assert drop_key_safely(
    {'a': 1, 'b': 2},
    'd') == {'a': 1, 'b': 2}
assert drop_key_safely(
    {'A': 2, 'B': 3, 'C': 4}, 'B'
) == {'A': 2, 'C': 4}
