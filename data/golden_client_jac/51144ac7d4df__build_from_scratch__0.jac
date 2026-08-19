def configure(*, host: str, port: int) -> None {
    print(f"Connecting to {host}:{port}");
}

with entry {
    configure(host="localhost", port=8080);   # OK
    # configure("localhost", 8080);           # Error: keyword-only
}
