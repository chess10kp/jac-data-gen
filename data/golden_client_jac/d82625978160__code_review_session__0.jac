# Objects persist when reachable from root
node User {
    has name: str;
}

with entry {
    user_node = User(name="Alice");
    root ++> user_node;
}
