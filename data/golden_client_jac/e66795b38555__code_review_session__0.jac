def process(data: any) {
    if data is None {
        raise ValueError("data must not be None");
    }
    if not isinstance(data, (int, str)) {
        raise TypeError("unsupported data type");
    }
    print(data);
}
def example(data: any) {
    try {
        process(data);
    } except (TypeError, ValueError) as e {
        print(f"Type or value error: {e}");
    }
}
