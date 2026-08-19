def to_snake_case(s: str) -> str {
    return s.lower().replace(" ", "_");
}

with entry {
    for x in ["Hello World", "Jac ML Studio", "The QUICK Brown Fox"] {
        print(to_snake_case(x));
    }
}
