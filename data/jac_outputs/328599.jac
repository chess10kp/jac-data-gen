"""Build config keys map."""
def build_config_keys_map(spec: dict[str, dict[str, list[dict[str, str]]]]) -> dict[str, dict[str, str]] {
    ss = [
        (s["config_key"], {"group": "streams_subscribes", "type": s["type"]})
        for s in spec["streams"]["subscribes"]
        if "config_key" in s
    ];
    sp = [
        (s["config_key"], {"group": "streams_publishes", "type": s["type"]})
        for s in spec["streams"]["publishes"]
    ];
    sc = [
        (s["config_key"], {"group": "services_calls"})
        for s in spec["services"]["calls"]
    ];
    return dict(ss + sp + sc);
}