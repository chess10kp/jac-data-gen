"""Return tree[seq[0][seq[1]][...] with the side-effect of creating all nodes in the path."""
def access(
    tree: dict[str | int, dict[str | int, int | str | float | bool | None] | int | str | float | bool | None],
    seq: list[str | int]
) -> dict[str | int, dict[str | int, int | str | float | bool | None] | int | str | float | bool | None] | int | str | float | bool | None {
    if len(seq) == 0 {
        return None;
    }
    if len(seq) == 1 {
        return tree[seq[0]];
    }
    return access(tree[seq[0]] as dict[str | int, dict[str | int, int | str | float | bool | None] | int | str | float | bool | None], seq[1:]);
}