"""
    Check if the given file is a ZIP
    Returns:
        bool: Whether it's a ZIP file or not
    """
def is_zip(file_type: Any) -> bool {
    mimes = {
        'application/zip',
        'application/octet-stream',
        'application/x-zip-compressed',
        'multipart/x-zip'
    };
    for v in mimes {
        if (v == file_type) {
            return True;
        }
    }
    return False;
}