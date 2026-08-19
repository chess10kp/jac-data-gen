def make_config(host: str = "localhost", port: int = 8080) -> dict {
    return {"host": host, "port": port, "url": f"http://{host}:{port}"};
}

with entry {
    config = make_config();
    print(config);
}
