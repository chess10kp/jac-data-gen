""" Old style model is stored with all names of parameters sharing common prefix 'module.' """
def remove_prefix(state_dict: dict[str, object], prefix: str) -> dict[str, object] {
    strip_prefix = lambda (key: str) { key.split(prefix, 1)[-1] if key.startswith(prefix) else key };
    {strip_prefix(key): value for (key, value) in state_dict.items()}
}