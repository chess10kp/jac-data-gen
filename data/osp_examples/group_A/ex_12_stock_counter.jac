"""Warehouse stock count: reading result.reports after a spawn.

The counter walker reports each item's quantity as it sweeps the
shelves. The entry block takes the returned walker object and reads
its reports list to compute totals without any global state.
"""

node StockItem {
    has sku: str = "";
    has quantity: int = 0;
}

walker StockCounter {
    can start with Root entry {
        visit [-->];
    }

    can count with StockItem entry {
        report here.quantity;
        visit [-->];
    }
}

with entry {
    root ++> StockItem(sku="WDG-01", quantity=120)
        ++> StockItem(sku="CBL-04", quantity=45)
        ++> StockItem(sku="BAT-09", quantity=310)
        ++> StockItem(sku="SCR-02", quantity=8);

    result = root spawn StockCounter();

    print(f"Per-item counts: {result.reports}");
    total = sum(result.reports);
    low = min(result.reports);
    print(f"Units in warehouse: {total}");
    print(f"Smallest shelf count: {low}");
}
