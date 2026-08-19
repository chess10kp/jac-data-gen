def cube_dictionary(n: Any) -> object {
    if (not isinstance(n, int) or (n <= 0)) {
        return {};
    }
    result = {};
    for i in range(1, (n + 1)) {
        result[i] = i ** 3;
    }
    return result;
}



with entry {
    print(cube_dictionary('hello'));
    print(cube_dictionary(5));
    print(cube_dictionary(10));
}
