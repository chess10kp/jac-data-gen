def describe(value: any) -> str {
    match value {
        case 0:
            return "zero";
        case 1 | 2 | 3:
            return "small number";
        case int() if value < 0:
            return "negative number";
        case int() if value > 100:
            return "large number";
        case _:
            return "something else";
    }
}
