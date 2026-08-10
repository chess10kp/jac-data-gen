"""Converts the pixel to grayscale using the given weights (or 1 by default) casting to int"""
def gray(px: Any, *weights: Any, cast: Any = int) -> object {
    y = w=cast(0);
    for x in range(len(px)) {
        z = cast(px[x]);
        try {
            y += z * weights[x];
            w += weights[x];
        } except Exception {
            y += z;
            w += 1;
        }
    }
    return (y / w);
}