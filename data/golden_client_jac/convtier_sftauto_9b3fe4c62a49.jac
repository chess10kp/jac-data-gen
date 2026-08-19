def has_unique_characters(s: Any) -> object {
    s = s.replace(" ", "");
    unique_chars = `set(s);
    return (len(s) == len(unique_chars));
}



with entry {
    print(has_unique_characters('hello'));
}
