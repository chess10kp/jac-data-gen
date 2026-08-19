def calculate_sum(input_list: Any) -> object {
    try {
        total = sum(input_list);
        return total;
    } except TypeError {
        raise InvalidInputError(
            "Invalid input. All elements in the list must be integers."
        );
    }
}



with entry {
    print(calculate_sum([]));
}
