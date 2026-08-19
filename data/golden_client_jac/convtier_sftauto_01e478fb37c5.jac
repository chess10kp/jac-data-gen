def round_to_nearest_integer(num: Any) -> object {
    if (num >= 0) {
        integer_part = int((num + 0.5));
    } else {
        integer_part = int((num - 0.5));
    }
    return integer_part;
}



with entry {
    print(round_to_nearest_integer(5));
    print(round_to_nearest_integer(10));
    print(round_to_nearest_integer(2));
}
