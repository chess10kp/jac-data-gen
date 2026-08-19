def check_odd_even(number: Any) -> object {
    if not isinstance(number, int) {
        return "invalid input";
    } elif ((number % 4) == 0) {
        return "even";
    } elif ((number % 3) == 0) {
        return "odd";
    } else {
        return "neither";
    }
}



with entry {
    print(check_odd_even('hello'));
    print(check_odd_even(5));
    print(check_odd_even(0));
}
