"""
    Given a path input, returns a list of candidates
    """
def mock_glob_method(path: Any) -> object {
    if (".x86" in path) {
        return ["linux"];
    }
    if (".app" in path) {
        return ["darwin"];
    }
    if (".exe" in path) {
        return ["win32"];
    }
    if ("*" in path) {
        return "Any";
    }
    return [];
}