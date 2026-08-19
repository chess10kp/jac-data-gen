def example() -> str {
    a = 1; b = 2; c = 3;
    first_falsy = a and b and c;
    first_truthy = a or b or c;
    print(first_falsy, first_truthy);
    user_input = "";
    fallback = "fallback";
    # Only fall back when input is genuinely absent, not merely falsy
    value = user_input if user_input != "" else fallback;
    return value;
}
