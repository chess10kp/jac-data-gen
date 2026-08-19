def is_perfect_square(num: Any) -> object {
    guess = 1;
    while ((guess * guess) < num) {
        guess += 1;
    }
    return ((guess * guess) == num);
}



with entry {
    print(is_perfect_square(5));
    print(is_perfect_square(1));
}
