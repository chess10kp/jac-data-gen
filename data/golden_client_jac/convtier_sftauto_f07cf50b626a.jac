def generate_random_string(n: Any) -> object {
    if ((n <= 0) or (n > 100)) {
        return "Invalid input! n should be a positive integer less than or equal to 100.";
    }
    uppercase_letter = random.choice(string.ascii_uppercase);
    lowercase_letters = ''.join(
        random.choice(string.ascii_lowercase) for _ in range((n - 1))
    );
    random_string = uppercase_letter + lowercase_letters;
    return random_string;
}



with entry {
    print(generate_random_string(0));
}
