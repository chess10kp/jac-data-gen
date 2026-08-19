def sum_of_digit_cubes(n: Any) -> object {
    if isinstance(n, int) {
        n = str(n);
    } elif not isinstance(n, str) {
        return "Error: Invalid parameter";
    }
    sum_of_cubes = 0;
    for digit in n {
        if digit.isdigit() {
            sum_of_cubes += int(digit) ** 3;
        }
    }
    return sum_of_cubes;
}



with entry {
    print(sum_of_digit_cubes('hello'));
    print(sum_of_digit_cubes(5));
    print(sum_of_digit_cubes(10));
}
