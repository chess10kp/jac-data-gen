def describe(value: any) -> str {
    match value {
        case 0:
            return "zero";
        case 1 | 2 | 3:
            return "small number";
        case _:
            return "something else";
    }
}
