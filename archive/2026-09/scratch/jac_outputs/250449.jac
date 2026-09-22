"""
    Tart-up a C function declaration: remove storage qualifiers,
    smush onto one line, escape asterisks.
    """
def massage_decl(decl: str) -> str {
    for storage in 'extern static inline'.split() {
        decl = decl.replace(storage + ' ', '');
    }
    fixed_lines = ' '.join(line.strip() for line in decl.splitlines());
    return fixed_lines.replace('*', '\\*');
}