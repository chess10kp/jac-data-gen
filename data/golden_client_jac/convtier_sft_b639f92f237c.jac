def dig(query: dict) -> str {
    spot = query["data"];
    try {
        for key in query["path"].split(".") {
            spot = spot[key];
        }
        return f"found: {spot}";
    } except KeyError as e {
        return f"missing key: {e}";
    } except TypeError {
        return "path too deep";
    }
}

with entry {
    print(dig({'data': {'a': {'b': 5}}, 'path': 'a.b'}));
}
