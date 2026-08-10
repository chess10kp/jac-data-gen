"""For list of object/attrib pairs confirm that the objects have the attrib."""
def has_required(*argv: dict[str, str] | str) -> bool {
    for i in range(0, len(argv), 2) {
        if not argv[i + 1] in argv[i] {
            return False;
        }
    }
    return True;
}