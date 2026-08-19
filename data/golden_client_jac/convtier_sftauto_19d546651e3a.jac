def generate_random_string(length: Any) -> object {
    random_string = "";
    for _ in range(length) {
        random_string += random.choice(string.ascii_letters);
    }
    return random_string;
}



with entry {
    print(generate_random_string(0));
}
