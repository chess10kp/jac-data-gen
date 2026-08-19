node Store {}
node Category { has name: str; }
node Product { has price: int; }

walker PriceAvg {
    has want: str;
    has total: int = 0;
    has count: int = 0;
    can start with Store entry { visit [-->][?:Category]; }
    can pick with Category entry {
        if here.name == self.want { visit [-->][?:Product]; }
    }
    can add with Product entry { self.total += here.price; self.count += 1; }
}

def avg_category_price(spec: dict) -> float {
    s = Store();
    for (cn, prices) in dict(spec["catalog"]).items() {
        c = Category(name=str(cn));
        s ++> c;
        for p in list(prices) { c ++> Product(price=int(p)); }
    }
    w = s spawn PriceAvg(want=str(spec["category"]));
    if w.count == 0 { return 0.0; }
    return w.total / w.count;
}

with entry {
    print(avg_category_price({'catalog': {'tools': [10, 20], 'toys': [5]}, 'category': 'tools'}));
}
