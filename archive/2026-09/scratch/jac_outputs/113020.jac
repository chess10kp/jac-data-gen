"""Returns True if circuit does not contain any gates from op_exclusions."""
def is_circuit_allowed_by_exclusion(op_exclusions: list, circuit: list) -> bool {
    return all(gate not in circuit for gate in op_exclusions);
}