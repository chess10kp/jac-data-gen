def sum_of_cubes(numbers: Any) -> object {
    if not numbers {
        return 0;
    }
    sum = 0;
    for num in numbers {
        if (num < 0) {
            raise ValueError("Negative integers are not allowed");
        }
        if ((num % 2) == 0) {
            sum += num ** 3;
        }
    }
    return sum;
}



with entry {
    print(sum_of_cubes(0));
    print(sum_of_cubes([2, 7]));
    print(sum_of_cubes([34]));
}
