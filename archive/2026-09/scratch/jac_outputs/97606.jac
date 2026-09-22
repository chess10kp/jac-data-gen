"""Returns "x implies y" / "x => y"."""
def implies(x: bool, y: bool) -> bool {
    not x or y
}