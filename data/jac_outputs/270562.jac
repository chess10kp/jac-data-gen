"""
    Takes a backup name and returns the base name.
    Example:
      Backup name = "test_bak_to_git.py.20211201_134317.bak"
        Base name = "test_bak_to_git.py"
    """
def bak_base_name(bak_name: Any) -> object {
    return bak_name.rsplit(".", 2)[0];
}