def restock_report(items: list[dict]) -> tuple[dict[str, int], list[str]] {
    totals: dict[str, int] = {};
    for it in items {
        totals[it["cat"]] = totals.get(it["cat"], 0) + it["qty"];
    }
    low: list[str] = sorted([it["name"] for it in items if it["qty"] < 5]);
    return (totals, low);
}

with entry {
    print(restock_report([{'name': 'bolt', 'cat': 'hw', 'qty': 12}, {'name': 'nut', 'cat': 'hw', 'qty': 3}, {'name': 'tape', 'cat': 'adh', 'qty': 4}]));
}
