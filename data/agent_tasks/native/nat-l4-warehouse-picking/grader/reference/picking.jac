"""Pick runs: walk the aisle chain and pull stock for an order."""
import from layout { Aisle, Bin, NextAisle, Holds }

obj PickLine {
    has aisle: int;
    has bin: str;
    has sku: str;
    has qty: int;
}

walker PickRun {
    has order: dict[str, int];
    has outstanding: dict[str, int] = {};
    has lines: list[PickLine] = [];
    has short: dict[str, int] = {};

    can start with Root entry {
        self.outstanding = dict(self.order);
        visit [-->[?:Aisle]];
    }

    can pick with Aisle entry {
        for b in [here ->:Holds:->] {
            want = self.outstanding.get(b.sku, 0);
            if want > 0 and b.qty > 0 {
                take = min(want, b.qty);
                b.qty -= take;
                self.outstanding[b.sku] = want - take;
                self.lines.append(PickLine(aisle=here.number, bin=b.code, sku=b.sku, qty=take));
            }
        }
        if any([n > 0 for n in self.outstanding.values()]) {
            visit [here ->:NextAisle:->];
        }
    }

    can finish with Root exit {
        self.short = {sku: n for (sku, n) in self.outstanding.items() if n > 0};
        report self.lines;
    }
}
