def cube_even_positive_numbers_recursive(lst: Any) -> object {
    cubes = [];
    for num in lst {
        if isinstance(num, (int, float, complex)) {
            if ((num >= 0) and ((num % 2) == 0)) {
                cubes.append((round(num) ** 3));
            }
        }
    }
    return cubes;
}



with entry {
    print(cube_even_positive_numbers_recursive('hello'));
    print(cube_even_positive_numbers_recursive([6, -12]));
}
