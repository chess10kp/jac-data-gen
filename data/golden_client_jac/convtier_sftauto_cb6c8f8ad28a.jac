def multiply_list(numbers: Any) -> object {
    result = 1;
    for number in numbers {
        result *= number;
    }
    return result;
}



with entry {
    print(multiply_list([]));
}
