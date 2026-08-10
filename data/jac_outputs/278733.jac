"""
Accepts a list of nonempty lists or indexable objects in argument alists and a keyword
argument recycle which if true will reuse elements in lists of shorter length.
Any error will result in an empty list to be returned.
"""
def splice(alists: list[list[int]], recycle: bool = True) -> list[int] {
    try {
        nlists = len(alists);
        lens = [len(alist) for alist in alists];
        totlen = sum(lens) if not recycle else max(lens) * nlists;
        pos = [0] * nlists;
        r = [0] * totlen;
        (i, j) = (0, 0);
        while i < totlen {
            if pos[j] < lens[j] {
                r[i] = alists[j][pos[j]];
                i += 1;
                pos[j] = pos[j] + 1;
                if recycle and pos[j] >= lens[j] {
                    pos[j] = 0;
                }
            }
            j = (j + 1) % nlists;
        }
        return r;
    } except Exception {
        return [];
    }
}