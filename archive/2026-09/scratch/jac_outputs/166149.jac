"""
    Every program in the tower lists its dependents.
    Look at the list and determine which program wasn't listed
    as dependent. That's the root.
    """
def find_root(tower: dict[str, tuple[int, list[str]]]) -> str | None {
    deps = {dep for (_, (_, holding)) in tower.items() for dep in holding};
    for (prog, (_, holding)) in tower.items() {
        if prog not in deps {
            return prog;
        }
    }
}