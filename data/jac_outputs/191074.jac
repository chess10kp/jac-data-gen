"""
    Slice config for printing as defined in key.
    """
def slice_config(
    config: dict[str, str | int | dict[str, str | int | dict]],
    key: str
) -> str | int | dict[str, str | int | dict] {
    current: str | int | dict[str, str | int | dict] = config;
    if key {
        keys = key.split('.');
        for k in keys {
            current = (current as dict[str, str | int | dict[str, str | int | dict]])[k];
        }
    }
    return current;
}