def parse_port(raw: str) -> str {
    try {
        port = int(raw);
        if port < 1 or port > 65535 {
            raise ValueError(f"port out of range: {port}");
        }
        return f"ok:{port}";
    } except ValueError as e {
        return f"invalid ({e})";
    }
}

with entry {
    print(parse_port('8080'));
}
