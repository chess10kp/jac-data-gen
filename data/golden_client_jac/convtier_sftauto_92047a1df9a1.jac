def odd_numbers_between_10_and_100(numbers: Any) -> object {
    result = [];
    for num in numbers {
        if ((num > 10) and (num < 100) and ((num % 2) != 0)) {
            result.append(num);
        }
    }
    return result;
}



with entry {
    print(odd_numbers_between_10_and_100([]));
}
