"""converts to nodeconfig."""
def nodeconfig(nodeconfig_line: str) -> dict[str, str] {
    config = {};
    for token in nodeconfig_line.split('; ') {
        pairs = token.split('=');
        if len(pairs) > 1 {
            config[pairs[0]] = pairs[1];
        }
    }
    return config;
}