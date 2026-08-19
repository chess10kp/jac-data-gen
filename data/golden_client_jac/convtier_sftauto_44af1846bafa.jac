def calculate_average(numbers: Any) -> object {
    if (len(numbers) < 5) {
        raise ValueError("List must contain at least 5 numbers");
    }
    for num in numbers {
        if ((num < 1) or (num > 100)) {
            raise ValueError("Numbers must be between 1 and 100 inclusive");
        }
    }
    average = round((sum(numbers) / len(numbers)));
    return average;
}



with entry {
    print(calculate_average([4, 2, 7, 1, 9]));
}
