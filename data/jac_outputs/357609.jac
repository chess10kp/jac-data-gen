"""Execute the given Python code."""
def execute(code: str) -> int | str | float | bool | list | dict | None {
    try {
        return eval(code, globals());
    } except Exception {
        return exec(code, globals());
    }
}