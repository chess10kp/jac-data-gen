def py_double(x: int) -> int {
    return x * 2;
}

def add_one_to_doubled(x: int) -> int {
    doubled: int = py_double(x);
    return doubled + 1;
}

with entry {
    print(add_one_to_doubled(5));  # prints 11
}
