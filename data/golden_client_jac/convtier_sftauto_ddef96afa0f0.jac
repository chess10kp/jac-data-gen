def dfs_binary_tree(`node: Any) -> object {
    visited = [];
    if `node {
        visited.append(`node.value);
        visited += dfs_binary_tree(`node.left);
        visited += dfs_binary_tree(`node.right);
    }
    return visited;
}



with entry {
    print(dfs_binary_tree(0));
}
