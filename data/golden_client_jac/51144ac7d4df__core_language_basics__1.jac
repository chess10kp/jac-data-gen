def configure(*, host: str, port: int = 8080) -> None {
    print(f"Connecting to {host}:{port}");
}

with entry {
    configure(host="localhost");           # OK
    # configure("localhost", 8080);        # Error: keyword-only
    configure(host="localhost", port=443); # OK
}
