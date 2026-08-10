"""Check for interface key, two possibilities."""
def is_key(config: dict) -> list {
    try {
        int_type = config.get('name', {}).get('#text', {});
    } except AttributeError {
        int_type = config['name'];
    }
    return int_type as list;
}