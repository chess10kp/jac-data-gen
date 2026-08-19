def cube(number: Any) -> object {
    result = 0;
    if (number < 0) {
        number = `abs(number);
        for i in range(number) {
            result += number * number * number;
        }
    } else {
        for i in range(number) {
            result += number * number * number;
        }
    }
    return result;
}



with entry {
    print(cube(5));
    print(cube(10));
    print(cube(2));
}
