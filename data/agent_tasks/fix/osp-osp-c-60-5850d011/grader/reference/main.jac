"""Warehouse inventory audit: assign stable ids, persist items to storage, and dump the root graph."""

node Item {
    has title: str = "";
    has sku: str = "";
    has quantity: int = 0;
    has item_id: int = 0;
}

node Storage {
    has records: list[dict[str, any]] = [];

    def add(record: dict[str, any]) -> None {
        self.records.append(record);
    }
}

edge Holds: any --> any { }

walker Auditor {
    has counter: int = 0;
    has storage: Storage = Storage();
    has snapshot: list[dict[str, any]] = [];

    can start with Root entry {
        visit [-->];
    }

    can step with Item entry {
        self.counter += 1;
        here.item_id = self.counter;
        record: dict[str, any] = {
            "item_id": here.item_id,
            "title": here.title,
            "sku": here.sku,
            "quantity": here.quantity,
        };
        self.snapshot.append(record);
        self.storage.add(record);
        print(f"persisted #{here.item_id} {here.title} (sku={here.sku}, qty={here.quantity})");
        visit [-->];
    }
}

walker GraphDumper {
    can start with Root entry {
        print("--- graph dump ---");
        print("root -> [Item nodes and Storage node connected via Holds edges]");
        visit [-->];
    }

    can describe_item with Item entry {
        print(f"  Item id={here.item_id} title={here.title} sku={here.sku} qty={here.quantity}");
        visit [-->];
    }

    can describe_storage with Storage entry {
        print(f"  Storage holds {len(here.records)} record(s):");
        for r in here.records {
            print(f"    {r}");
        }
        visit [-->];
    }
}

with entry {
    warehouse = Storage();
    root +>:Holds:+> Item(title="Bolts", sku="BLT-001", quantity=500);
    root +>:Holds:+> Item(title="Cogs", sku="COG-014", quantity=120);
    root +>:Holds:+> Item(title="Rivets", sku="RIV-220", quantity=0);
    root +>:Holds:+> warehouse;

    audit = Auditor(storage=warehouse);
    root spawn audit;

    print("\nFinal id assignments:");
    for r in audit.snapshot {
        print(f"  {r}");
    }

    dumper = GraphDumper();
    root spawn dumper;
}
