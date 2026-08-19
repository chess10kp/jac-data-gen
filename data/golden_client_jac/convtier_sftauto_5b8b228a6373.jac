def sum_of_cube_even_numbers(n: Any) -> object {
    if (not isinstance(n, int) or (n < 0)) {
        raise ValueError("Input must be a positive integer");
    }
    sum_of_cubes = 0;
    for num in range(2, (n + 1), 2) {
        sum_of_cubes += num ** 3;
    }
    return sum_of_cubes;
}



with entry {
    print(sum_of_cube_even_numbers(5));
    print(sum_of_cube_even_numbers(10));
    print(sum_of_cube_even_numbers(2));
}
