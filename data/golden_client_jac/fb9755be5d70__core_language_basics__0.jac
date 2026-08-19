def describe(value: int) -> str {
    match value {
        case 0:
            return "zero";
        case 1 | 2 | 3:
            return "small";
        case _:
            return "medium";
    }
}

with entry {
    print(describe(0));    # zero
    print(describe(2));    # small
    print(describe(50));   # medium
}
