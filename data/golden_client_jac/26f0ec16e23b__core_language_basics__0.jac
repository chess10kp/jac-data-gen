def example() {
    a = 1; b = 2; c = 3;

    # 'and' stops at first falsy value
    result = a and b and c;  # Returns first falsy, or last value

    # 'or' stops at first truthy value
    result = a or b or c;    # Returns first truthy, or last value

    # Common patterns
    user_input = "";
    fallback = "fallback";
    value = user_input or fallback;     # Use fallback if input is falsy
}
