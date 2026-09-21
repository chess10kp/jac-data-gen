"""Audit an inventory graph: stable ids, persistence, and structure.

The warehouse auditor prints the stable Jac id of every shelf item so
downstream systems can reference them, persists new items to storage,
and dumps the whole graph layout from the root for a visual check.
"""

node Item {
    has sku: str;
    has qty: int;
}

node Aisle {
    has name: str;
}

edge StoredIn {}

walker Auditor {
    has reports: list[str] = [];

    can start with Root entry {
        visit [-->];
    }

    can walk_aisle with Aisle entry {
        print(f"[{here.name}]");
        # Items point INTO the aisle via StoredIn, so query incoming
        items = [<-:StoredIn:<-];

        for it in items {
            # jid: stable identifier usable as an external reference
            self.reports.append(f"{it.sku} x{it.qty} (id={jid(it)})");
            save(it);   # persist the item now, not just at run end
        }

        if not items {
            print("  empty aisle");
        }
        visit [-->];
    }

    can finish with Root exit {
        print("-- Inventory with stable ids --");
        for line in self.reports {
            print(line);
        }
        print("-- Graph structure from root --");
        printgraph(root);
    }
}

with entry {
    aisle3 = Aisle(name="Aisle 3");
    bolts = Item(sku="BLT-M8", qty=500);
    washers = Item(sku="WSH-M8", qty=1200);

    root ++> aisle3;
    bolts +>: StoredIn() :+> aisle3;
    washers +>: StoredIn() :+> aisle3;

    root spawn Auditor();
}
