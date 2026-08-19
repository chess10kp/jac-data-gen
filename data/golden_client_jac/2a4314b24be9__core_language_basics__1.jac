with entry {
    config = (def () -> dict {
        host = "localhost";
        port = 8080;
        return {"host": host, "port": port, "url": f"http://{host}:{port}"};
    })();
    print(config);
}
