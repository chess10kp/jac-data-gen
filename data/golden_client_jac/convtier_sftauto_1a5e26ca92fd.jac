def find_data_type(expression: Any) -> object {
    if isinstance(expression, `list) {
        return "list";
    } else {
        raise InvalidDataTypeError("Invalid data type: the expression is not a list.");
    }
}



with entry {
    print(find_data_type([]));
}
