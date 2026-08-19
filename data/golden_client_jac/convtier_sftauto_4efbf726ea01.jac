def square_elements(input_list: Any) -> object {
    result = [];
    for num in input_list {
        result.append((num ** 2));
    }
    return result;
}



with entry {
    print(square_elements([]));
}
