"""Demo entry point for the warehouse project."""
import from seed { build_warehouse }
import from picking { PickRun, PickLine }

def summary(lines: list[PickLine], short: dict[str, int]) -> str {
    return "picked " + str(len(lines)) + " lines, short " + str(sum(short.values())) + " units";
}

with entry {
    build_warehouse([
        [("A1-01", "bolt", 40), ("A1-02", "nut", 10)],
        [("A2-01", "nut", 25), ("A2-02", "washer", 5)],
        [("A3-01", "bolt", 15)]
    ]);
    print("warehouse ready");
    w = root spawn PickRun(order={"bolt": 50, "nut": 12, "washer": 9});
    print(summary(w.reports[0], w.short));
}
