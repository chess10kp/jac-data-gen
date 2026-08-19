with entry {
    # Allow a specific user to read this node
    allow_root(node, target_root_id, READ);

    # Allow write access
    allow_root(node, target_root_id, WRITE);
}
