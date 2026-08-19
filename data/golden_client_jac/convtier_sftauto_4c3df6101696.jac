def remove_duplicates(lst: Any) -> object {
    unique_numbers = [];
    for num in lst {
        if (num not in unique_numbers) {
            unique_numbers.append(num);
        }
    }
    unique_numbers.sort();
    return len(unique_numbers);
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
