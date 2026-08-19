with entry {
    config = (def () -> dict {
        host = "localhost";
        port = 8080;
        return {"host": host, "port": port};
    })();
    print(config);
}
