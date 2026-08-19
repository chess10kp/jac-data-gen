def first_repeated_letter(string: Any) -> object {
    seen = `set();
    for (i, c) in enumerate(string) {
        if (c == ' ') {
            continue;
        }
        if (c in seen) {
            return i;
        }
        seen.add(c);
    }
    return -1;
}



with entry {
    print(first_repeated_letter('hello'));
    print(first_repeated_letter('Racecar'));
    print(first_repeated_letter('step on no pets'));
}
