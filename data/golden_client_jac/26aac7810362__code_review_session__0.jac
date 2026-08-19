walker _before_request {
    has request: dict;

    can log with `root entry {
        method = self.request.get("method", "?");
        path = self.request.get("path", "?");
        print(f"Request: {method} {path}");
    }
}
