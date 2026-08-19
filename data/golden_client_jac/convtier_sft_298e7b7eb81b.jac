node City { has name: str; }
node Shop { has sid: str; }
node Item { has sid: str; has qty: int; }

walker StockAudit {
    has totals: dict = {};
    can open with City entry { visit [-->][?:Shop]; }
    can reg with Shop entry {
        self.totals[here.sid] = 0;
        visit [-->][?:Item];
    }
    can add with Item entry { self.totals[here.sid] += here.qty; }
}

def fully_stocked_cities(spec: dict) -> int {
    low: int = int(spec["min"]);
    count: int = 0;
    for (cn, shops) in dict(spec["cities"]).items() {
        c = City(name=str(cn));
        for (sn, qtys) in dict(shops).items() {
            s = Shop(sid=str(sn));
            c ++> s;
            for q in list(qtys) { s ++> Item(sid=str(sn), qty=int(q)); }
        }
        w = c spawn StockAudit();
        good: bool = len(w.totals) > 0;
        for v in w.totals.values() { if v < low { good = False; } }
        if good { count += 1; }
    }
    return count;
}

with entry {
    print(fully_stocked_cities({'cities': {'rome': {'alpha': [3, 4], 'beta': [9]}, 'oslo': {'solo': [1]}}, 'min': 5}));
}
