node Depot {}
node Warehouse { has name: str; }
node Item { has name: str; has qty: int; }

walker StockSum {
    has target: str;
    has total: int = 0;
    can start with Depot entry { visit [-->][?:Warehouse]; }
    can descend with Warehouse entry { visit [-->][?:Item]; }
    can add with Item entry { if here.name == self.target { self.total += here.qty; } }
}

def sum_item_stock(spec: dict) -> int {
    d = Depot();
    for (wn, stock) in dict(spec["warehouses"]).items() {
        w = Warehouse(name=str(wn));
        d ++> w;
        for (inm, q) in dict(stock).items() { w ++> Item(name=str(inm), qty=int(q)); }
    }
    return (d spawn StockSum(target=str(spec["item"]))).total;
}

with entry {
    print(sum_item_stock({'warehouses': {'east': {'bolt': 4, 'nut': 9}, 'west': {'bolt': 6}}, 'item': 'bolt'}));
}
