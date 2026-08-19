def describe_value(x: object) -> str {
    match x {
        case int():
            return f"Integer: {x}";
        case str():
            return f"String: {x}";
        case list():
            return f"List with {len(x)} items";
    }
}

with entry {
    print(describe_value(42));
    print(describe_value("hello"));
    print(describe_value([1, 2, 3]));
}
