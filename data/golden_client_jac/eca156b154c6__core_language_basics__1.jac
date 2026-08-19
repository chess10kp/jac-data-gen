def example() {
    # Falsy values
    if not 0 { print("0 is falsy"); }
    if not "" { print("empty string is falsy"); }
    if not [] { print("empty list is falsy"); }
    if not None { print("None is falsy"); }

    # Truthy values
    if 1 { print("non-zero is truthy"); }
    if "hello" { print("non-empty string is truthy"); }
    if [1, 2] { print("non-empty list is truthy"); }

    # Common patterns
    items = [1, 2, 3];
    if items {
        print(items);
    } else {
        print("No items to process");
    }

    # Default value pattern
    user_input = "";
    name = user_input or "Anonymous";
}
