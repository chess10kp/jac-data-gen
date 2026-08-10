"""
    Utility function to test if something is a directory.
    """
def is_dir(f: dict[str, str]) -> bool {
    return f['mimeType'] == 'application/vnd.google-apps.folder';
}