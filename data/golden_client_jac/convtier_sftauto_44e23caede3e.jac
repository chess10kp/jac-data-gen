def remove_duplicates(numbers: Any) -> object {
    distinct_values = `set();
    for num in numbers {
        if (num > 0) {
            distinct_values.add(num);
        }
    }
    distinct_list = `list(distinct_values);
    distinct_list.sort(reverse=True);
    return distinct_list;
}



with entry {
    print(remove_duplicates([81]));
    print(remove_duplicates([]));
    print(remove_duplicates([100]));
}
