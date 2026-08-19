def count_uppercase(string: Any) -> object {
    count = 0;
    skip_next = False;
    for i in range(len(string)) {
        if skip_next {
            skip_next = False;
            continue;
        }
        if string[i].isupper() {
            if (((i + 1) < len(string)) and string[(i + 1)].islower()) {
                skip_next = True;
            } else {
                count += 1;
            }
        }
    }
    return count;
}



with entry {
    print(count_uppercase('hello'));
}
