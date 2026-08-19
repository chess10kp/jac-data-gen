def example(data: any) {
    match data {
        case [1, *middle, 5]:              # Spread: capture remainder
            print(f"Middle: {middle}");

        case {"key1": 1, **rest}:          # Dict spread
            print(f"Rest: {rest}");

        case [1, 2, last as captured]:     # As: bind to name
            print(f"Captured: {captured}");

        case [1, 2] | [3, 4]:              # Or: match either
            print("Matched");
    }
}
