"""Variables that are read before they are written in the block."""
def use(block: list[dict[str, list[str] | str]]) -> set[str] {
    defined = set();
    used = set();
    for i in block {
        used.update(
            v
            for v in i.get('args', [])
            if v not in defined
        );
        if 'dest' in i {
            defined.add(i['dest']);
        }
    }
    return used;
}