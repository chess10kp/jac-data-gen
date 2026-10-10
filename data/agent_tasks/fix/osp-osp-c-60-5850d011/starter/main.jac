"""Warehouse inventory audit.

Each Item is given a stable unique id at creation time so external
systems can reference it. As the auditor walker traverses the
warehouse graph it "persists" every item to a storage log (printed
record). At the end of the walk the structure hanging off root is
dumped for a visual sanity check.
"""

node Item {
    has sku: str = "";
    has label: str = "";
    has qty: int = 0;
    has item_id: str = "";

    can stamp with Root entry {
        if self.item_id == "" {
            seed = "ROOT";
            self.item_id = f"WH-{seed}-{abs(hash(self.label)) % 100000}";
        }
        visit [-->];
    }
}

walker Auditor {
    has storage: list[str] = [];
    has seen: set[str] = set();
    has log_label: str = "MAIN-WAREHOUSE";

    can start with Root entry {
        print(f"=== Audit begin: {self.log_label} ===");
        visit [-->];
    }

    can enter with Item entry {
        if here.item_id == "" {
            here.item_id = f"WH-{self.log_label}-{abs(hash(here.label)) % 100000}";
        }
        if here.item_id not in self.seen {
            self.seen.add(here.item_id);
            self.storage.append(
                f"[PERSIST] id={here.item_id} sku={here.sku} "
                f"label={here.label} qty={here.qty}"
            );
        }
        visit [-->];
    }
}

walker Dumper {
    can start with Root entry {
        print("=== Graph dump (root) ===");
        for child in [-->] {
            print(f"- {child}");
            for grand in [child -->] {
                print(f"    -> {grand}");
            }
        }
    }
}

with entry {
    root ++> Item(sku="A-001", label="Pallet of Bolts", qty=240)
        ++> Item(sku="A-002", label="Drum of Lubricant", qty=12)
        ++> Item(sku="A-003", label="Crate of Gaskets", qty=80);

    auditor = Auditor(log_label="BAY-3");
    root spawn auditor;
    for line in auditor.storage {
        print(line);
    }
    print(f"Total persisted: {auditor.storage}");
    print(f"Unique ids seen: {auditor.seen}");

    root spawn Dumper();
}