def round_float(input: Any) -> object {
    if (input <= 0) {
        return "Invalid input";
    } elif ((input < 1) or (input > 1000)) {
        return "Input out of range";
    } else {
        return round(input, 2);
    }
}



with entry {
    print(round_float(5));
    print(round_float(10));
    print(round_float(2));
}
