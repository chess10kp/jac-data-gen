"""Demo entry point for the warehouse project."""
import from seed { build_warehouse }

with entry {
    build_warehouse([
        [("A1-01", "bolt", 40), ("A1-02", "nut", 10)],
        [("A2-01", "nut", 25), ("A2-02", "washer", 5)],
        [("A3-01", "bolt", 15)]
    ]);
    print("warehouse ready");
    # TODO: run a pick for the demo order below and print the summary line
    # demo order: bolt x50, nut x12, washer x9
}
