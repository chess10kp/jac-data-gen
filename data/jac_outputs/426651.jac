"""Returns whether or not a given module can be imported."""
def has_module(module_name: str, members: list[str] = []) -> bool {
    try {
        mod = __import__(module_name, fromlist=members);
    } except ImportError {
        return False;
    }
    for member in members {
        if not hasattr(mod, member) {
            return False;
        }
    }
    return True;
}