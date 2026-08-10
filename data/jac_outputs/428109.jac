"""
Coerces pathlib Path objects to a string (only python version 3.6+)
any other objects passed to this function will be returned as is.
"""
def pathToString(filepath: object) -> object {
    if hasattr(filepath, "__fspath__") {
        return getattr(filepath, "__fspath__")();
    }
    return filepath;
}