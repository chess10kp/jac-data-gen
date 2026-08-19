import json;

def example(raw: str) {
    try {
        data = json.loads(raw);
        print(data);
    } except ValueError as e {
        print(f"Parse error: {e}");
    }
}
