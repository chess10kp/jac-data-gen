"""Validate label for group/nodeset/pset."""
def validateLabel(value: str) -> str {
    if len(value) == 0 {
        raise ValueError(
            "Label for boundary condition group/nodeset/pset in mesh not specified."
        );
    }
    return value;
}