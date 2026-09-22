"""Shows only the Python traceback."""
def only_python_traceback(info: dict[str, str], level: int = 9) -> str {
    if level > 0 {
        return info["simulated_python_traceback"];
    }
    return info["python_traceback"];
}