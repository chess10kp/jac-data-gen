"""Build a warehouse from a compact spec (used by main.jac and by our tests)."""
import from layout { Aisle, Bin, NextAisle, Holds }

"""spec: one list per aisle, each bin as (code, sku, qty). Returns the first aisle."""
def build_warehouse(spec: list[list[tuple[str, str, int]]]) -> Aisle | None {
    first: Aisle | None = None;
    prev: Aisle | None = None;
    for (i, bins) in enumerate(spec) {
        aisle = Aisle(number=i + 1);
        if prev is None {
            root ++> aisle;
            first = aisle;
        } else {
            prev +>:NextAisle():+> aisle;
        }
        for (code, sku, qty) in bins {
            aisle +>:Holds():+> Bin(code=code, sku=sku, qty=qty);
        }
        prev = aisle;
    }
    return first;
}
