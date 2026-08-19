def remove_duplicates_and_sort(numbers: Any) -> object {
    unique_numbers = `list(`set(numbers));
    unique_numbers.sort(reverse=True);
    return unique_numbers;
}



with entry {
    print(remove_duplicates_and_sort('hello'));
    print(remove_duplicates_and_sort('Racecar'));
    print(remove_duplicates_and_sort('abcabc'));
}
