def _is_lib(fn: str, osname: str) -> bool;

impl _is_lib {
    return fn.endswith(".dylib") if osname == "Darwin" else fn.startswith("libraylib.so");
}
