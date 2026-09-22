"""Invert the sign of the given symmetry operation."""
def invert_sym(sym_op: str) -> str {
    sym_op = sym_op.lower();
    new_op = sym_op.replace('x', '-x').replace('y', '-y').replace('z', '-z').replace('--', '+').replace('+-', '-');
    return new_op;
}