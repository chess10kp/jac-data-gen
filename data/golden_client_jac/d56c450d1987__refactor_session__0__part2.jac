obj ArgTools {
    static def sum_all(*values: int) -> int {
        return sum(values);
    }
    static def build_config(**options: object) -> dict {
        return dict(options);
    }
    static def flexible(required: int, *args: int, **kwargs: object) -> None {
        print(f"Required: {required}");
        print(f"Extra positional: {args}");
        print(f"Extra keyword: {kwargs}");
    }
}
with entry {
    ArgTools.sum_all(1, 2, 3, 4, 5);
    ArgTools.build_config(debug=True, verbose=False);
    ArgTools.flexible(1, 2, 3, name="test");
}
