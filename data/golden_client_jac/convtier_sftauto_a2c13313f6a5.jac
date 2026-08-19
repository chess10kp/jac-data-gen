def square_root(number: Any) -> object {
    guess = number / 2;
    threshold = 0.0001;
    while (`abs(((guess * guess) - number)) > threshold) {
        guess = (guess + (number / guess)) / 2;
    }
    return guess;
}



with entry {
    print(square_root(5));
    print(square_root(10));
    print(square_root(2));
}
