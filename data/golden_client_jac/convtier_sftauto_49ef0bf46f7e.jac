def remove_duplicates_and_sort(numbers: Any) -> object {
    numbers.sort();
    new_list = [];
    for num in numbers {
        if (num not in new_list) {
            new_list.append(num);
        }
    }
    return new_list;
}



with entry {
    print(remove_duplicates_and_sort([]));
}
