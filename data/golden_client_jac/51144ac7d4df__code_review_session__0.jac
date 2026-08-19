def configure(*, host: str, port: int = 8080) -> None {
    if port < 0 or port > 65535 {
        raise ValueError(f"Invalid port: {port}");
    }
    print(f"Connecting to {host}:{port}");
}

with entry {
    configure(host="localhost");           # OK
    configure(host="localhost", port=443); # OK
}
