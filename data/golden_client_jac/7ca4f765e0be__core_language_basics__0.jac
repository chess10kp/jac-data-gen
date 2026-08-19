import json;

def example(input: str) {
    try {
        data = json.loads(input);
    } except ValueError as e {
        print(f"Parse error: {e}");
    } except KeyError as e {
        print(f"Missing key: {e}");
    }
}
