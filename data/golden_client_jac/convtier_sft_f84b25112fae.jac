def title_case(s: str) -> str {
    return " ".join([word.capitalize() for word in s.split()]);
}

with entry {
    print(title_case("hello world"));
}
