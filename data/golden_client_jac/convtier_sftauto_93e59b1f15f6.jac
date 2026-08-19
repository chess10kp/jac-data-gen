def find_max(lst: Any) -> object {
    max_value = float('-inf');
    for num in lst {
        if (num > max_value) {
            max_value = num;
        }
    }
    return max_value;
}



with entry {
    print(find_max([]));
}
