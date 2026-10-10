"""Key functions for memoizing caches (port of cachetools.keys).

Upstream wraps keys in a private `_HashedTuple` that caches its hash; a plain
tuple is behaviorally identical (same equality and hash), so it is used here.
"""
import operator;
import from collections.abc { Hashable }

"""Marker class separating positional args from keyword args inside a key."""
obj KwMark {}

glob _KWMARK: tuple[any, ...] = (KwMark,);

"""Cache key for the given hashable arguments."""
def hashkey(*args: Hashable, **kwargs: Hashable) -> tuple[any, ...] {
    if kwargs {
        return tuple(args) + _KWMARK + tuple(sorted(kwargs.items(), key=operator.itemgetter(0)));
    }
    return tuple(args);
}

"""Like hashkey, but also distinguishes argument types (1 vs 1.0)."""
def typedkey(*args: Hashable, **kwargs: Hashable) -> tuple[any, ...] {
    key = hashkey(*args, **kwargs);
    if kwargs {
        key = key + tuple([type(v) for (_, v) in sorted(kwargs.items(), key=operator.itemgetter(0))]);
    }
    return key + tuple([type(v) for v in args]);
}

"""Key for cached methods: ignores the instance argument."""
def methodkey(instance: any, *args: Hashable, **kwargs: Hashable) -> tuple[any, ...] {
    return hashkey(*args, **kwargs);
}
