def custom_sqrt(number: Any) -> object {
    if (number == 0) {
        return 0;
    }
    guess = number;
    previous_guess = 0;
    while (`abs((guess - previous_guess)) >= 0.01) {
        previous_guess = guess;
        guess = (guess + (number / guess)) / 2;
    }
    return round(guess, 2);
}



with entry {
    print(custom_sqrt(5));
    print(custom_sqrt(10));
    print(custom_sqrt(2));
}
