"""_log: prefix lifted into a named module-level constant."""

glob _LOG_PREFIX: str = ">> ";

def _log(msg: str) -> None {
    print(_LOG_PREFIX + msg);
}

with entry {
    _log("compiling shooter");
    _log("staged raylib shared library set");
}
