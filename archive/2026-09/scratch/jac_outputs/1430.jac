"""Splits dictionary numbers by the decimal point."""
type SplitTree = float | int | dict[str, int | float] | list[SplitTree];

def splitter(h: SplitTree) -> SplitTree {
    if isinstance(h, dict) {
        for (k, i) in h.items() {
            (h as dict[str, list[str]])[k] = str(i).split(".");
        }
    }
    if isinstance(h, list) {
        for n in range(len(h)) {
            h[n] = splitter(h[n] as SplitTree);
        }
    }
    return h;
}