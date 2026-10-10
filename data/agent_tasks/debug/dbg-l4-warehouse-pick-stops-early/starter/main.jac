"""Demo entry point for the warehouse project."""
import from seed { build_warehouse }
import from picking { PickRun }

with entry {
    build_warehouse([
        [("A1-01", "bolt", 40), ("A1-02", "nut", 10)],
        [("A2-01", "nut", 25), ("A2-02", "washer", 5)],
        [("A3-01", "bolt", 15)]
    ]);
    print("warehouse ready");
    run = root spawn PickRun(order={"bolt": 50, "nut": 12, "washer": 9});
    missing = sum(run.short.values());
    print(f"picked {len(run.reports[0])} lines, short {missing} units");
}
