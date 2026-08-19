def example() -> str {
    if not 0 { print("0 is falsy"); }
    if not "" { print("empty string is falsy"); }
    if not [] { print("empty list is falsy"); }
    if not None { print("None is falsy"); }

    if 1 { print("non-zero is truthy"); }
    if "hello" { print("non-empty string is truthy"); }
    if [1, 2] { print("non-empty list is truthy"); }

    items = [1, 2, 3];
    if items {
        print(items);
    } else {
        print("No items to process");
    }

    user_input = "";
    name = user_input or "Anonymous";

    # New: coalesce a config value with a default
    config = {};
    timeout = config.get("timeout") or 30;
    return f"{name}:{timeout}";
}

with entry {
    print(example());
}
