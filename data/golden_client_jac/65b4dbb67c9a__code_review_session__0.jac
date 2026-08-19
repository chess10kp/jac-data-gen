def add(a: int, b: int, c: int) -> int {
    return a + b + c;
}

with entry {
    # Unpack list/tuple into positional args
    values = [1, 2, 3];
    print(add(*values));  # add(1, 2, 3)

    # Unpack dict into keyword args
    params = {"a": 1, "b": 2, "c": 3};
    print(add(**params));  # add(a=1, b=2, c=3)

    # Combined unpacking
    print(add(*[1, 2], **{"c": 3}));  # add(1, 2, c=3)
}
