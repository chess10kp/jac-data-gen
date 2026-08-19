def is_even_or_odd(num: Any) -> object {
    if ((num % 2) == 0) {
        return "even";
    } else {
        return "odd";
    }
}



with entry {
    print(is_even_or_odd(5));
    print(is_even_or_odd(10));
}
