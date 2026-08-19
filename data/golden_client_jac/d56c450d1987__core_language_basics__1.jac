# *args collects extra positional arguments
def sum_all(*values: int) -> int {
    return sum(values);
}

# **kwargs collects extra keyword arguments
def build_config(**options: object) -> dict {
    return dict(options);
}

# Combined
def flexible(required: int, *args: int, **kwargs: object) -> None {
    print(f"Required: {required}");
    print(f"Extra positional: {args}");
    print(f"Extra keyword: {kwargs}");
}

with entry {
    sum_all(1, 2, 3, 4, 5);  # 15
    build_config(debug=True, verbose=False);  # {"debug": True, "verbose": False}
    flexible(1, 2, 3, name="test");
    # Required: 1
    # Extra positional: (2, 3)
    # Extra keyword: {"name": "test"}
}
