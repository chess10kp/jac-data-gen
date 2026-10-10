import from layout { Aisle, Bin, NextAisle, Holds }
import from seed { build_warehouse }
import from picking { PickLine, PickRun }

def bin_qty(code: str) -> int {
    for b in [root -->[?:Aisle] ->:Holds:->] {
        if b.code == code {
            return b.qty;
        }
    }
    for a in [root -->[?:Aisle]] {
        cur = [a];
        while cur {
            for b in [cur[0] ->:Holds:->] {
                if b.code == code {
                    return b.qty;
                }
            }
            cur = [cur[0] ->:NextAisle:->];
        }
    }
    return -99;
}

def lines_of(w: PickRun) -> list[str] {
    return [f"{l.aisle}:{l.bin}:{l.sku}:{l.qty}" for l in w.reports[0]];
}

test "single aisle pick decrements stock" {
    build_warehouse([[("x1", "bolt", 10), ("x2", "nut", 4)]]);
    w = root spawn PickRun(order={"bolt": 3});
    assert len(w.reports) == 1;
    assert lines_of(w) == ["1:x1:bolt:3"];
    assert bin_qty("x1") == 7;
    assert bin_qty("x2") == 4;
    assert len(w.short) == 0;
}

test "splits across bins and aisles in chain order" {
    build_warehouse([
        [("a1", "bolt", 4), ("a2", "nut", 1), ("a3", "bolt", 2)],
        [("b1", "nut", 5)],
        [("c1", "bolt", 100)]
    ]);
    w = root spawn PickRun(order={"bolt": 10, "nut": 3});
    assert lines_of(w) == ["1:a1:bolt:4", "1:a2:nut:1", "1:a3:bolt:2", "2:b1:nut:2", "3:c1:bolt:4"];
    assert bin_qty("a1") == 0;
    assert bin_qty("b1") == 3;
    assert bin_qty("c1") == 96;
}

test "stops once the order is filled" {
    build_warehouse([[("a1", "nut", 5)], [("b1", "nut", 5)]]);
    w = root spawn PickRun(order={"nut": 5});
    assert lines_of(w) == ["1:a1:nut:5"];
    assert bin_qty("b1") == 5;
}

test "shortages reported and empty bins skipped" {
    build_warehouse([[("a1", "gear", 0), ("a2", "gear", 2)], [("b1", "cog", 1)]]);
    w = root spawn PickRun(order={"gear": 5, "cog": 1, "pin": 3});
    assert lines_of(w) == ["1:a2:gear:2", "2:b1:cog:1"];
    assert w.short == {"gear": 3, "pin": 3};
}

test "order dict is not mutated" {
    build_warehouse([[("a1", "nut", 5)]]);
    order = {"nut": 2, "bolt": 1};
    root spawn PickRun(order=order);
    assert order == {"nut": 2, "bolt": 1};
}

test "second run sees stock reduced by the first" {
    build_warehouse([[("a1", "nut", 5)]]);
    root spawn PickRun(order={"nut": 4});
    w = root spawn PickRun(order={"nut": 4});
    assert lines_of(w) == ["1:a1:nut:1"];
    assert w.short == {"nut": 3};
}
