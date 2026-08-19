def _ensure_jac_runtime() -> None {}
def _discover_config_from_file(filename: str) -> None {}
def _proc_file(filename: str) -> tuple {
    return ("", None, None);
}

def run(filename: str, main: bool = True, cache: bool = True, verbose: bool = False) -> int;

impl run(filename: str, main: bool = True, cache: bool = True, verbose: bool = False) -> int {
    _ensure_jac_runtime();
    _discover_config_from_file(filename);
    (base, mod, mach) = _proc_file(filename);
    if verbose {
        print(f"Running {filename} (main={main}, cache={cache})");
    }
    return 0;
}
