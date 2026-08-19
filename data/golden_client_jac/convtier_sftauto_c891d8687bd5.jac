def cube_dictionary(n: Any) -> object {
    if (not isinstance(n, int) or (n <= 0)) {
        raise CustomException("n must be a positive integer");
    }
    if (n > (10 ** 6)) {
        raise CustomException("n must be less than or equal to 10^6");
    }
    cubes = {};
    for i in range(1, (n + 1)) {
        cubes[i] = i * i * i;
    }
    return cubes;
}



with entry {
    print(cube_dictionary(5));
    print(cube_dictionary(10));
    print(cube_dictionary(2));
}
