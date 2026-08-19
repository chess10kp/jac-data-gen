def calculate_bits(`bytes: Any) -> object {
    try {
        if (isinstance(`bytes, int) and (`bytes >= 0)) {
            return (`bytes * 8);
        } else {
            raise ValueError("Input must be a non-negative integer.");
        }
    } except TypeError {
        raise ValueError("Input must be a non-negative integer.");
    } except ValueError as e {
        raise ValueError(e);
    }
}



with entry {
    print(calculate_bits(5));
    print(calculate_bits(10));
    print(calculate_bits(2));
}
