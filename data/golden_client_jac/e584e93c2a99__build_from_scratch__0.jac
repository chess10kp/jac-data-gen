def _is_lib(fn: str, osname: str) -> bool {
    if osname == "Darwin" {
        return fn.endswith(".dylib");
    }
    return fn.endswith(".so");
}
