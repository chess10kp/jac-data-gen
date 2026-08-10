"""Strictly sublists; no equality here."""
def listIn(container: list[int], maybe_contained: list[int], *, strict: bool = True) -> int | None {
    lc = len(container);
    lmc = len(maybe_contained);
    if lc > lmc or not strict and lc == lmc {
        z = maybe_contained[0];
        if z in container {
            substart = container.index(z);
            subcontained = maybe_contained[1:];
            if not subcontained {
                return substart;
            }
            ssp1 = substart + 1;
            subcontainer = container[ssp1:];
            maybe = listIn(subcontainer, subcontained, strict=False);
            if maybe is None or maybe > 0 {
                maybe = listIn(subcontainer, maybe_contained, strict=False);
                if maybe is not None {
                    return ssp1 + maybe;
                }
            } else {
                return substart;
            }
        }
    }
}