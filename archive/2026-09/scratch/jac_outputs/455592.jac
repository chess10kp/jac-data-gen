"""Returns True if example contains any atom in atoms."""
def _contains_atom(example: Any, atoms: Any, get_atoms_fn: Any) -> object {
    example_atoms = get_atoms_fn(example);
    for example_atom in example_atoms {
        if (example_atom in atoms) {
            return True;
        }
    }
    return False;
}