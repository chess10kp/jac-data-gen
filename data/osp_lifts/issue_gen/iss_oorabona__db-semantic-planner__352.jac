"""oorabona/db-semantic-planner#352 — cross-branch js: read metadata agreement fold."""

obj SchemaFold {
    has branches: list[list[dict[str, str | None]]] = [];
}

def load_branch_metadata(
    branches: list[list[dict[str, str | None]]],
) -> SchemaFold {
    fold = SchemaFold();
    for row in branches { fold.branches.append(list(row)); }
    return fold;
}

def fold_js_read_at(fold: SchemaFold, position: int) -> str | None {
    if len(fold.branches) == 0 { return None; }
    width = len(fold.branches[0]);
    if position < 0 or position >= width { return None; }
    agreed: str | None = None;
    for branch in fold.branches {
        if position >= len(branch) { return None; }
        meta = branch[position].get("js", None);
        if meta is None { return None; }
        if agreed is None { agreed = meta; }
        elif meta != agreed { return None; }
    }
    return agreed;
}

def fold_js_read_metadata(fold: SchemaFold) -> list[str | None] {
    if len(fold.branches) == 0 { return []; }
    width = len(fold.branches[0]);
    out: list[str | None] = [];
    for i in range(width) { out.append(fold_js_read_at(fold, i)); }
    return out;
}

def should_convert(fold: SchemaFold, position: int) -> bool {
    return fold_js_read_at(fold, position) is not None;
}
