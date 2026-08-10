"""Get resource name from path (first value before '.')"""
def resource_from_path(path: str) -> str {
    index = path.find('.');
    if index == -1 {
        return path;
    }
    return path[:index];
}