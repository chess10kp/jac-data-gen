"""Pick runs: walk the aisle chain and pull stock for an order."""
import from layout { Aisle, Bin, NextAisle, Holds }

obj PickLine {
    has aisle: int;
    has bin: str;
    has sku: str;
    has qty: int;
}

def remaining(todo: dict[str, int]) -> int {
    total = 0;
    for v in todo.values() {
        total += v;
    }
    return total;
}

"""Eager variant: follows the chain itself in a loop from the first aisle."""
walker PickRun {
    has order: dict[str, int];
    has short: dict[str, int] = {};

    can run with Root entry {
        todo: dict[str, int] = {};
        for (k, v) in self.order.items() {
            todo[k] = v;
        }
        picked: list[PickLine] = [];
        aisles = [here -->[?:Aisle]];
        cur: Aisle | None = aisles[0] if aisles else None;
        while cur is not None and remaining(todo) > 0 {
            for b in [cur -->[?:Bin]] {
                if b.sku in todo and todo[b.sku] > 0 and b.qty > 0 {
                    n = todo[b.sku] if todo[b.sku] < b.qty else b.qty;
                    b.qty = b.qty - n;
                    todo[b.sku] = todo[b.sku] - n;
                    picked.append(PickLine(aisle=cur.number, bin=b.code, sku=b.sku, qty=n));
                }
            }
            nxt = [cur ->:NextAisle:->];
            cur = nxt[0] if nxt else None;
        }
        for (k, v) in todo.items() {
            if v > 0 {
                self.short[k] = v;
            }
        }
        report picked;
    }
}
