# app.jac

# Standard Jac -- runs on Python
def process_data(items: list[dict]) -> list[dict] {
    # Full access to PyPI, walkers, by llm(), etc.
    return [item for item in items if item["active"]];
}

na {
    # Native codespace -- compiles to machine code
    def compute_checksum(data: list[int]) -> int {
        has result: int = 0;
        for val in data {
            result = (result * 31 + val) % 1000000007;
        }
        return result;
    }

    def fibonacci(n: int) -> int {
        if n <= 1 { return n; }
        return fibonacci(n - 1) + fibonacci(n - 2);
    }
}

with entry {
    # Call both Python and native functions seamlessly
    print(compute_checksum([1, 2, 3, 4, 5]));
    print(fibonacci(30));
}
