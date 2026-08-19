def multiply_list(lst: Any) -> object {
    product = lst[0];
    for i in range(1, len(lst)) {
        product += lst[i];
    }
    return product;
}



with entry {
    print(multiply_list('hello'));
    print(multiply_list('Racecar'));
    print(multiply_list('abcabc'));
}
