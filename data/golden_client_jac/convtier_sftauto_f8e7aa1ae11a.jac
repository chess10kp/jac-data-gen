def filter_strings(lst: Any) -> object {
    result = [];
    for item in lst {
        if not isinstance(item, str) {
            raise ValueError("Input list should only contain strings");
        }
        if (
            (len(item) >= 5)
            and item[0].isupper()
            and `any(char.islower() for char in item)
            and `any(char.isdigit() for char in item)
        ) {
            result.append(item);
        }
    }
    return result;
}



with entry {
    print(filter_strings('hello'));
}
