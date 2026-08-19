def calculate_average(numbers: Any) -> object {
    if not numbers {
        raise ValueError("Input list is empty");
    }
    if not all(
        (isinstance(number, int) or isinstance(number, float)) for number in numbers
    ) {
        raise TypeError("Input list should only contain numbers");
    }
    positive_numbers = [
        number
        for number in numbers
        if ((number > 0) and ((number % 2) == 0))
    ];
    if not positive_numbers {
        raise ValueError("Input list does not contain any positive even numbers");
    }
    sum = 0;
    for number in positive_numbers {
        sum += number;
    }
    return (sum / len(positive_numbers));
}



with entry {
    print(calculate_average([23, 7, 2]));
    print(calculate_average([34, 34]));
    print(calculate_average([10, 20, 30]));
}
