"""Handle tick-count action."""
def handle_count(data: dict[str, object]) -> dict[str, int | str] {
    try {
        print("Data: {}".format(data));
        if data["status"] == "error" {
            return {"cmd": "put", "msg": 'put\ntick\n{"count": 0}\n'};
        }
        if "value" in data and "count" in data["value"] {
            current_count = int(data["value"]["count"]);
            return {"cmd": "tick", "msg": current_count};
        }
        return {"cmd": "get", "msg": "get\ntick\n"};
    } except KeyError {
        raise KeyError("Server sent unknown message");
    }
}