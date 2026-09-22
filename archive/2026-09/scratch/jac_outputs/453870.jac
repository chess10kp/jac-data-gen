"""Generate a PEP386 compliant version string."""
def get_version(v: tuple[int, int, int, str, int]) -> str {
    assert isinstance(v, tuple);
    assert len(v) == 5;
    assert v[3] in ('alpha', 'beta', 'rc', 'final');
    parts = 2 if v[2] == 0 else 3;
    main = '.'.join(str(i) for i in v[:parts]);
    sub = '';
    if v[3] != 'final' {
        mapping = {'alpha': 'a', 'beta': 'b', 'rc': 'c'};
        sub = mapping[v[3]] + str(v[4]);
    }
    return str(main + sub);
}