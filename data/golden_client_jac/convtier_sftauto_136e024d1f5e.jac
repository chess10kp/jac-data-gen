def square_and_hex_stringify(lst: Any) -> object {
    modified_lst = [hex((num ** 2))[2:] for num in lst];
    return ", ".join(modified_lst);
}



with entry {
    print(square_and_hex_stringify([]));
}
