def generate_array(N: Any) -> object {
    array = [];
    for _ in range(N) {
        length = random.randint(5, 10);
        string = '';
        for _ in range(length) {
            string += random.choice(string.ascii_lowercase);
        }
        string = insert_special_character(string);
        string = insert_uppercase_letter(string);
        string = insert_digit(string);
        array.append(string);
    }
    return array;
}



with entry {
    print(generate_array(0));
}
