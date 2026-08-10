"""Split module_name.signal_name to module_name , signal_name
    """
def get_ms_name(name: str) -> tuple[str, str | None] {
    tokens = name.split('.');
    if len(tokens) == 0 {
        raise SystemExit("This to be catched in validate.py");
    }
    module = tokens[0];
    signal = None;
    if len(tokens) == 2 {
        signal = tokens[1];
    }
    return (module, signal);
}