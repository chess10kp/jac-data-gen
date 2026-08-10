"""Normalize a casual index like "one, two, 3,four" to canonical form like ["one", "two", 3, "four"]."""
def splitIndex(index: Any) -> object {
    out = [x.strip() for x in index.split(",")];
    for i in range(len(out)) {
        try {
            out[i] = int(out[i]);
        } except ValueError {
            ;
        }
    }
    return out;
}