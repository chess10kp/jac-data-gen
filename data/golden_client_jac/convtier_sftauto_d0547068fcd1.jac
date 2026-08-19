def is_odd(x: Any) -> object {
    if ((x % 2) == 1) {
        return True;
    }
    return False;
}



with entry {
    print(is_odd(5));
    print(is_odd(10));
}
