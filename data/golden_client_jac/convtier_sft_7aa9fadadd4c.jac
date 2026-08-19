node Depot {}
node Warehouse { has name: str; }
node Item { has wh: str; has qty: int; }

walker ShortageScan {
    has low: int;
    has hit: list = [];
    can start with Depot entry { visit [-->][?:Warehouse]; }
    can descend with Warehouse entry { visit [-->][?:Item]; }
    can flag with Item entry {
        if here.qty < self.low and here.wh not in self.hit { self.hit.append(here.wh); }
    }
}

def low_stock_warehouses(spec: dict) -> int {
    d = Depot();
    for (wn, stock) in dict(spec["warehouses"]).items() {
        w = Warehouse(name=str(wn));
        d ++> w;
        for (inm, q) in dict(stock).items() { w ++> Item(wh=str(wn), qty=int(q)); }
    }
    return len((d spawn ShortageScan(low=int(spec["min"]))).hit);
}

with entry {
    print(low_stock_warehouses({'warehouses': {'east': {'bolt': 2, 'nut': 9}, 'west': {'rod': 7}}, 'min': 3}));
}
