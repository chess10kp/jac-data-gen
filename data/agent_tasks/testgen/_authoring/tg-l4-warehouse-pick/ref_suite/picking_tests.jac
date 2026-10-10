import from layout { Aisle, Bin, NextAisle, Holds }
import from seed { build_warehouse }
import from picking { PickLine, PickRun }

def all_bins() -> list[Bin] {
    out: list[Bin] = [];
    cur = [root -->[?:Aisle]];
    while cur {
        out.extend([cur[0] ->:Holds:->]);
        cur = [cur[0] ->:NextAisle:->];
    }
    return out;
}

def qty(code: str) -> int {
    for b in all_bins() {
        if b.code == code {
            return b.qty;
        }
    }
    return -1;
}

def lines(w: PickRun) -> list[str] {
    return [f"{l.aisle}/{l.bin}/{l.sku}/{l.qty}" for l in w.reports[0]];
}

test "build_warehouse chains aisles from root" {
    first = build_warehouse([[("a", "x", 1)], [("b", "y", 2)], [("c", "z", 3)]]);
    assert first.number == 1;
    assert len([root -->[?:Aisle]]) == 1;
    second = [first ->:NextAisle:->][0];
    assert second.number == 2;
    assert [[second ->:NextAisle:->][0].number] == [3];
    assert [b.code for b in all_bins()] == ["a", "b", "c"];
}

test "empty spec builds nothing" {
    assert build_warehouse([]) is None;
    assert len([root -->[?:Aisle]]) == 0;
}

test "simple pick takes from one bin" {
    build_warehouse([[("A1", "bolt", 10)]]);
    w = root spawn PickRun(order={"bolt": 4});
    assert len(w.reports) == 1;
    assert lines(w) == ["1/A1/bolt/4"];
    assert qty("A1") == 6;
    assert len(w.short) == 0;
    assert w.aisles_visited == 1;
}

test "exact quantity empties the bin" {
    build_warehouse([[("A1", "bolt", 3)]]);
    w = root spawn PickRun(order={"bolt": 3});
    assert lines(w) == ["1/A1/bolt/3"];
    assert qty("A1") == 0;
    assert len(w.short) == 0;
}

test "unordered skus are left alone" {
    build_warehouse([[("A1", "bolt", 5), ("A2", "nut", 5)]]);
    w = root spawn PickRun(order={"nut": 2});
    assert lines(w) == ["1/A2/nut/2"];
    assert qty("A1") == 5;
    assert qty("A2") == 3;
}

test "pick spans bins then aisles in order" {
    build_warehouse([
        [("A1", "nut", 2), ("A2", "bolt", 1), ("A3", "nut", 3)],
        [("B1", "bolt", 1)],
        [("C1", "nut", 50), ("C2", "bolt", 50)]
    ]);
    w = root spawn PickRun(order={"nut": 7, "bolt": 3});
    assert lines(w) == ["1/A1/nut/2", "1/A2/bolt/1", "1/A3/nut/3", "2/B1/bolt/1", "3/C1/nut/2", "3/C2/bolt/1"];
    assert qty("C1") == 48;
    assert qty("C2") == 49;
    assert w.aisles_visited == 3;
}

test "run stops at the aisle where the order completes" {
    build_warehouse([[("A1", "nut", 1)], [("B1", "nut", 1)], [("C1", "nut", 1)]]);
    w = root spawn PickRun(order={"nut": 2});
    assert lines(w) == ["1/A1/nut/1", "2/B1/nut/1"];
    assert w.aisles_visited == 2;
    assert qty("C1") == 1;
}

test "shortage when stock runs out and for unknown skus" {
    build_warehouse([[("A1", "gear", 0), ("A2", "gear", 1)], [("B1", "gear", 1)]]);
    w = root spawn PickRun(order={"gear": 5, "spring": 2});
    assert lines(w) == ["1/A2/gear/1", "2/B1/gear/1"];
    assert w.short == {"gear": 3, "spring": 2};
    assert w.aisles_visited == 2;
}

test "zero quantity order lines are not short" {
    build_warehouse([[("A1", "gear", 4)]]);
    w = root spawn PickRun(order={"gear": 0});
    assert len(w.reports[0]) == 0;
    assert len(w.short) == 0;
    assert qty("A1") == 4;
}

test "caller's order dict is not changed" {
    build_warehouse([[("A1", "nut", 9)]]);
    order = {"nut": 4, "cam": 1};
    w = root spawn PickRun(order=order);
    assert order["nut"] == 4;
    assert order["cam"] == 1;
    assert w.outstanding["nut"] == 0;
}

test "successive runs see reduced stock" {
    build_warehouse([[("A1", "nut", 5)]]);
    root spawn PickRun(order={"nut": 3});
    w = root spawn PickRun(order={"nut": 3});
    assert lines(w) == ["1/A1/nut/2"];
    assert w.short == {"nut": 1};
    assert qty("A1") == 0;
}
