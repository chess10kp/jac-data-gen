def convert_inches_to_cm(inches: Any) -> object {
    if (`type(inches) not in [float, int]) {
        raise TypeError(
            "Invalid input type. Only float and integer values are allowed."
        );
    }
    if (inches < 0) {
        raise ValueError("Negative values are not allowed.");
    }
    return (inches * 2.54);
}



with entry {
    print(convert_inches_to_cm(5));
    print(convert_inches_to_cm(10));
    print(convert_inches_to_cm(2));
}
