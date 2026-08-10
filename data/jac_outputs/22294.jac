"""Add a file to a tree.

    Args:

        tree
            A list of dicts containing info about each blob in a tree.

        file_path
            The path of the new file in the tree.

        file_contents
            The (UTF-8 encoded) contents of the new file.

        is_executable
            If ``True``, the new file will get executable permissions (0755).
            Otherwise, it will get 0644 permissions.

    Returns:
        The provided tree, but with the new file added.

    """
def add_file_to_tree(
    tree: list[dict[str, str]],
    file_path: str,
    file_contents: str,
    is_executable: bool = False
) -> list[dict[str, str]] {
    record = {
        "path": file_path,
        "mode": "100755" if is_executable else "100644",
        "type": "blob",
        "content": file_contents
    };
    tree.append(record);
    return tree;
}