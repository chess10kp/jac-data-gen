"""flatten( sequence[, max_depth[, ltypes]] ) => sequence

    Flatten every sequence in "l" whose type is contained in "ltypes"
    to "max_depth" levels down the tree.  See the module documentation
    for a complete description of this function.

    The sequence returned has the same type as the input sequence.
    """
def flatten(l: Any, max_depth: Any = None, ltypes: Any = (`list, `tuple)) -> object {
    if (max_depth is None) {
        make_flat = lambda (x: Any) { True; };
    } else {
        make_flat = lambda (x: Any) { (max_depth > len(x)); };
    }
    if callable(ltypes) {
        is_sequence = ltypes;
    } else {
        is_sequence = lambda (x: Any) { isinstance(x, ltypes); };
    }
    r = `list();
    s = `list();
    s.append((0, l));
    while s {
        (i, l) = s.pop();
        while (i < len(l)) {
            while is_sequence(l[i]) {
                if not l[i] {
                    break;
                } elif make_flat(s) {
                    s.append(((i + 1), l));
                    l = l[i];
                    i = 0;
                } else {
                    r.append(l[i]);
                    break;
                }
            } else {
                r.append(l[i]);
            }
            i += 1;
        }
    }
    try {
        return `type(l)(r);
    } except TypeError {
        return r;
    }
}