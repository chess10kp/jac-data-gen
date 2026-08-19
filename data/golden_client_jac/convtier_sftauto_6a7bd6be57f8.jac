def remove_duplicates(numbers: Any) -> object {
    unique_numbers = [];
    for num in numbers {
        if ((num >= 0) and ((num % 3) != 0)) {
            if (num not in unique_numbers) {
                unique_numbers.append(num);
            }
        }
    }
    return unique_numbers;
}



with entry {
    print(remove_duplicates([2, 9]));
    print(remove_duplicates([34]));
    print(remove_duplicates([10, 20, 30]));
}
