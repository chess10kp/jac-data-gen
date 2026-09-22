"""Check wether a NAG function name is valid."""
def validate_nag_function_name(name: str | None) -> bool {
    return (
        name is not None
        and isinstance(name, str)
        and len(name) > 1
        and name[1:].isdigit()
        and (name[0:1] in ('i', 'n', 'o') or name in ('c0', 'c1'))
        and name[0:2] not in ('i0', 'n0', 'o0')
    );
}