def cube_list(numbers: Any) -> object {
    cube_numbers = [];
    for num in numbers {
        cube = num ** 3;
        cube_numbers.append(cube);
    }
    return cube_numbers;
}



with entry {
    print(cube_list([]));
}
