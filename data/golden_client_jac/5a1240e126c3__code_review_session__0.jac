def process_data(items: list[dict]) -> list[dict] {
    return [item for item in items if item["active"]];
}

def compute_checksum(data: list[int]) -> int {
    result: int = 0;
    for val in data {
        result = (result * 31 + val) % 1000000007;
    }
    return result;
}

def fibonacci(n: int) -> int {
    if n <= 1 { return n; }
    return fibonacci(n - 1) + fibonacci(n - 2);
}

with entry {
    print(compute_checksum([1, 2, 3, 4, 5]));
    print(fibonacci(30));
}
