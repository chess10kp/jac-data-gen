"""_m_ident: the fixed identity matrix lifted to a constant; a copy is returned."""

glob _IDENT: list[float] = [
    1.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0,
    0.0, 0.0, 0.0, 1.0
];

def _m_ident() -> list {
    return list(_IDENT);
}

with entry {
    print(str(_m_ident()));
}
