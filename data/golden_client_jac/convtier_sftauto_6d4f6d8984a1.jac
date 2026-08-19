def find_second_largest(numbers: Any) -> object {
    unique_numbers = `list(`set(numbers));
    if (len(unique_numbers) < 2) {
        return -1;
    } else {
        unique_numbers.sort();
        return unique_numbers[-2];
    }
}



with entry {
    print(find_second_largest('hello'));
    print(find_second_largest('Racecar'));
    print(find_second_largest('abcabc'));
}
