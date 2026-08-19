node Todo {
    has title: str;
}


# PUBLIC - shared root, everyone sees the same data.
def:pub total_public_todos() -> int {
    return len([root -->][?:Todo]);
}


# PRIVATE - per-user root, each caller sees only their own data.
# Same query code, different subgraph per user.
def:priv my_todos() -> list[Todo] {
    return [root -->][?:Todo];
}

def:priv add_todo(title: str) -> Todo {
    return (root ++> Todo(title=title))[0];
}
