"""
Creates a residue "key" for a node. Keys should be identical only for nodes
that are part of the same residue.
"""
def _residue_key_func(`node: dict[str, int | str | None]) -> tuple[int | None, str | None, int | None, str | None] {
    attrs = ("mol_idx", "chain", "resid", "resname");
    return tuple(`node.get(attr) for attr in attrs);
}