def check_string(string: Any) -> object {
    divisible_count = 0;
    divisible_indices = [];
    for (i, char) in enumerate(string) {
        if (char.isupper() or char.isdigit()) {
            if (char.isdigit() and ((int(char) % 3) == 0)) {
                divisible_count += 1;
                divisible_indices.append(i);
            }
        } else {
            return False;
        }
    }
    return (True, divisible_count, sorted(divisible_indices));
}



with entry {
    print(check_string('hello'));
}
