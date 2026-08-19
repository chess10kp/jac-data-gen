def create_random_string(input_string: Any) -> object {
    new_string = "";
    index = 0;
    length = len(input_string);
    while (len(new_string) < 10) {
        index = (index + 1) % length;
        new_string += input_string[index];
    }
    return new_string;
}



with entry {
    print(create_random_string('hello'));
    print(create_random_string('Racecar'));
    print(create_random_string('abcabc'));
}
