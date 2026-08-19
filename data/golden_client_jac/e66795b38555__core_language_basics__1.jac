def process(data: any) -> None {
    print(data);
}

def example(data: any) {
    try {
        process(data);
    } except (TypeError, ValueError) as e {
        print(f"Type or value error: {e}");
    }
}
