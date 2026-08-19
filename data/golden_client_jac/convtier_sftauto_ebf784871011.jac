def second_largest_unique_value(arr: Any) -> object {
    unique_values = `set(arr);
    unique_values.remove(max(arr));
    return max(unique_values);
}



with entry {
    print(second_largest_unique_value('hello'));
    print(second_largest_unique_value('Racecar'));
    print(second_largest_unique_value('abcabc'));
}
