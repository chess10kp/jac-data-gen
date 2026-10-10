"""Test annex for warehouse inventory audit program."""
import from main { Auditor, GraphDumper, Item, Storage }

import io;
import from contextlib { redirect_stdout }

test "auditor assigns stable sequential ids to items" {
    warehouse = Storage();
    root ++> Item(title="Bolts", sku="BLT-001", quantity=500);
    root ++> Item(title="Cogs", sku="COG-014", quantity=120);
    root ++> Item(title="Rivets", sku="RIV-220", quantity=0);
    root ++> warehouse;

    audit = Auditor(storage=warehouse);
    res = root spawn audit;

    items = [root -->];
    id_set = set();
    for n in items {
        if isinstance(n, Item) {
            id_set.add(n.item_id);
        }
    }
    assert len(id_set) == 3, f"expected 3 distinct item_ids, got {id_set}";

    expected_ids = [1, 2, 3];
    for n in items {
        if isinstance(n, Item) {
            assert n.item_id in expected_ids, f"unexpected item_id {n.item_id}";
        }
    }

    assert res.counter == 3, f"counter should be 3, got {res.counter}";
}

test "auditor persists each item to the supplied storage" {
    warehouse = Storage();
    root ++> Item(title="Bolts", sku="BLT-001", quantity=500);
    root ++> Item(title="Cogs", sku="COG-014", quantity=120);
    root ++> Item(title="Rivets", sku="RIV-220", quantity=0);
    root ++> warehouse;

    audit = Auditor(storage=warehouse);
    res = root spawn audit;

    assert len(res.storage.records) == 3, f"expected 3 stored records, got {len(res.storage.records)}";

    titles = set();
    skus = set();
    for r in res.storage.records {
        titles.add(r["title"]);
        skus.add(r["sku"]);
        assert r["item_id"] >= 1, f"record item_id should be >=1, got {r}";
        assert "quantity" in r, f"record missing quantity: {r}";
    }
    assert "Bolts" in titles, f"missing Bolts in {res.storage.records}";
    assert "Cogs" in titles, f"missing Cogs in {res.storage.records}";
    assert "Rivets" in titles, f"missing Rivets in {res.storage.records}";

    assert len(res.snapshot) == 3, f"snapshot length mismatch: {len(res.snapshot)}";
}

test "auditor prints a persistence line per item" {
    warehouse = Storage();
    root ++> Item(title="Bolts", sku="BLT-001", quantity=500);
    root ++> Item(title="Cogs", sku="COG-014", quantity=120);
    root ++> Item(title="Rivets", sku="RIV-220", quantity=0);
    root ++> warehouse;

    buf = io.StringIO();
    with redirect_stdout(buf) {
        audit = Auditor(storage=warehouse);
        res = root spawn audit;
    }
    out = buf.getvalue();

    assert "persisted #1 Bolts (sku=BLT-001, qty=500)" in out, f"missing bolts line: {out}";
    assert "persisted #2 Cogs (sku=COG-014, qty=120)" in out, f"missing cogs line: {out}";
    assert "persisted #3 Rivets (sku=RIV-220, qty=0)" in out, f"missing rivets line: {out}";
}

test "graph dumper describes items and storage contents" {
    warehouse = Storage();
    root ++> Item(title="Bolts", sku="BLT-001", quantity=500);
    root ++> Item(title="Cogs", sku="COG-014", quantity=120);
    root ++> Item(title="Rivets", sku="RIV-220", quantity=0);
    root ++> warehouse;

    buf = io.StringIO();
    with redirect_stdout(buf) {
        audit = Auditor(storage=warehouse);
        res = root spawn audit;
        dumper = GraphDumper();
        root spawn dumper;
    }
    out = buf.getvalue();

    assert "--- graph dump ---" in out, f"missing graph dump header: {out}";
    assert "Item id=" in out, f"missing item line in dump: {out}";
    assert "title=Bolts" in out, f"missing Bolts title in dump: {out}";
    assert "Storage holds 3 record(s)" in out, f"missing storage summary: {out}";

    items = [root -->];
    for n in items {
        if isinstance(n, Item) {
            assert f"id={n.item_id}" in out, f"id {n.item_id} not printed in dump: {out}";
        }
    }
}

test "auditor with no items produces no records and stable state" {
    warehouse = Storage();
    root ++> warehouse;

    audit = Auditor(storage=warehouse);
    res = root spawn audit;

    assert res.counter == 0, f"counter should remain 0, got {res.counter}";
    assert len(res.snapshot) == 0, f"snapshot should be empty, got {res.snapshot}";
    assert len(res.storage.records) == 0, f"storage should remain empty, got {res.storage.records}";
}
