glob config: dict[str, any] = {
    "debug": True,
    "version": "1.0.0"
};

def get_version() -> str {
    return config["version"];
}

with entry {
    print(get_version());  # 1.0.0
}
