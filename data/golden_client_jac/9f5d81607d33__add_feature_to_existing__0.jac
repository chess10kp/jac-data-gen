match value {
    case 0: return "zero";
    case 1 | 2 | 3: return "small number";
    case _: return "something else";
    case int() if value < 0: return "negative number";
}
