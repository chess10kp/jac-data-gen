def generate_random_string(length: Any) -> object {
    alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    random_string = "";
    for _ in range(length) {
        random_index = random.randint(0, (len(alphabet) - 1));
        random_char = alphabet[random_index];
        random_string += random_char;
    }
    return random_string;
}



with entry {
    print(generate_random_string(0));
}
