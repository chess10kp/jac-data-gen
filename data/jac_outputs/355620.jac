"""Ensure the destination does have a trailing /"""
def sanitize_dest(path: str) -> str {
    return path if path.endswith("/") else path + "/";
}