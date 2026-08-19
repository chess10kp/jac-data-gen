def square_root(n: Any) -> object {
    if (n < 0) {
        return complex(0, (`abs(n) ** 0.5));
    }
    guess = n / 2;
    while True {
        new_guess = (guess + (n / guess)) / 2;
        if (`abs((new_guess - guess)) < 1e-10) {
            return new_guess;
        }
        guess = new_guess;
    }
}



with entry {
    print(square_root(5));
    print(square_root(10));
    print(square_root(2));
}
