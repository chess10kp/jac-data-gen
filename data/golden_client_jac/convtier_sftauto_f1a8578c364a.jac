def detect_even_odd(number: Any) -> object {
    if (not isinstance(number, int) or (number <= 0) or (number > 1000)) {
        return "Invalid Input";
    } elif ((number % 2) == 0) {
        return "Even";
    } else {
        return "Odd";
    }
}



with entry {
    print(detect_even_odd('hello'));
    print(detect_even_odd(5));
    print(detect_even_odd(10));
}
