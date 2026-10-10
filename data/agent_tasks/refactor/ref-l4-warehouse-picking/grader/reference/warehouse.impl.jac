"""Implementations for warehouse.jac."""

impl pick_order(a: Aisle) -> list[Bin] {
    out: list[Bin] = [];
    for lv in sorted(set([h.level for h in [edge a ->:Holds:->]])) {
        out.extend([a ->:Holds:level == lv:->]);
    }
    return out;
}

impl PickRun.start {
    self.want = dict(self.order);
    visit [here -->[?:Aisle]];
}

impl PickRun.on_aisle {
    self.entered += 1;
    for b in pick_order(here) {
        need = self.want.get(b.sku, 0);
        if need > 0 and b.qty > 0 and b.state == BinState.OPEN {
            take = min(need, b.qty);
            self.want[b.sku] = need - take;
            if self.commit {
                b.qty -= take;
            }
            self.lines.append(f"A{here.number}/{b.code} {b.sku} x{take}");
        }
    }
    if any([n > 0 for n in self.want.values()]) {
        visit [here ->:NextAisle:->];
    }
}

impl FindBin.start {
    visit [here -->[?:Aisle]];
}

impl FindBin.on_aisle {
    wanted = self.code;
    hits = [here ->:Holds:->[?:Bin, code == wanted]];
    if hits {
        self.found = hits[0];
    } else {
        visit [here ->:NextAisle:->];
    }
}

impl OnHand.start {
    visit [here -->[?:Aisle]];
}

impl OnHand.on_aisle {
    wanted = self.sku;
    for b in [here ->:Holds:->[?:Bin, sku == wanted]] {
        if b.state == BinState.OPEN {
            self.total += b.qty;
        }
    }
    visit [here ->:NextAisle:->];
}

impl Warehouse.aisle(number: int) -> Aisle | None {
    cur = [self -->[?:Aisle]];
    while cur {
        if cur[0].number == number {
            return cur[0];
        }
        cur = [cur[0] ->:NextAisle:->];
    }
    return None;
}

impl Warehouse.add_aisle -> int {
    new_aisle = Aisle(number=self.aisle_count + 1);
    last = self.aisle(self.aisle_count);
    if last is None {
        self ++> new_aisle;
    } else {
        last +>:NextAisle():+> new_aisle;
    }
    self.aisle_count += 1;
    return self.aisle_count;
}

impl Warehouse.stock(aisle: int, code: str, sku: str, qty: int, level: int) -> bool {
    a = self.aisle(aisle);
    if a is None or (self spawn FindBin(code=code)).found is not None {
        return False;
    }
    a +>:Holds(level=level):+> Bin(code=code, sku=sku, qty=qty);
    return True;
}

impl Warehouse.block_bin(code: str) -> bool {
    b = (self spawn FindBin(code=code)).found;
    if b is None or b.state == BinState.BLOCKED {
        return False;
    }
    b.state = BinState.BLOCKED;
    return True;
}

impl Warehouse.on_hand(sku: str) -> int {
    return (self spawn OnHand(sku=sku)).total;
}

impl Warehouse.pick(order: dict[str, int]) -> list[str] {
    return (self spawn PickRun(order=order)).lines;
}

impl Warehouse.aisles_needed(order: dict[str, int]) -> int {
    return (self spawn PickRun(order=order, commit=False)).entered;
}
