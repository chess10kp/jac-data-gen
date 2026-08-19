def example(data: any) {
    match data {
        case [1, *middle, 5]:
            print(f"Middle: {middle}");
        case {"key1": 1, **rest}:
            print(f"Rest: {rest}");
        case [1, 2, captured]:
            print(f"Captured: {captured}");
        case [1, 2] | [3, 4]:
            print("Matched");
        case _:
            print("no match");
    }
}
