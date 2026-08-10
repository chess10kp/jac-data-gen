"""Is this a Microsoft Office temp file?"""
def _is_temp_garbage(filename: str) -> bool {
    return filename.startswith("~$") or filename.endswith(".tmp");
}