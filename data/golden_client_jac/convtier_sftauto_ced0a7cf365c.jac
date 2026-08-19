def calculate_average(numbers: Any) -> object {
    if not numbers {
        return 0;
    }
    return (sum(numbers) / len(numbers));
}



with entry {
    print(calculate_average(0));
}
