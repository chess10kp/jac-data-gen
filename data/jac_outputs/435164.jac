"""Drive letter is not allowed to be project environment.
Script checks in parent of 'path': a drive letter like C: doesn't have a parent."""
def verify_dlg_sdk_proj_env_directory(path: str) -> bool {
    return path.find(":\\") + 2 < len(path);
}