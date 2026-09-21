"""Inspection utility: jid, save, commit, and printgraph in one script.

Prints each node's unique id, persists explicitly, flushes pending
changes, and dumps the stored structure.
"""

node Account {
    has owner: str;
    has balance: float = 0.0;
}

edge Owes {
    has amount: float = 0.0;
}

walker build_ledger {
    has entries: list[tuple[str, str, float]];

    can run with Root entry {
        made: dict[str, Account] = {};
        for (a_name, b_name, amt) in self.entries {
            if a_name not in made {
                made[a_name] = here ++> Account(owner=a_name);
            }
            if b_name not in made {
                made[b_name] = here ++> Account(owner=b_name);
            }
            made[a_name] +>: Owes(amount=amt) :+> made[b_name];
        }
        report {"accounts": sorted(made.keys())};
    }
}

with entry {
    root spawn build_ledger(entries=[
        ("alice", "bob", 12.5),
        ("bob", "carol", 4.0),
        ("carol", "alice", 7.25),
    ]);

    # jid: stable unique id -- the handle clients keep for later updates.
    for acct in [root -->][?:Account] {  # anchor at root in free code
        print(jid(acct), "->", acct.owner);
        save(acct);  # persist this node now
    }

    commit();  # flush all pending writes to storage

    # Structure dump. printgraph writes through the logging system, so its
    # visibility depends on logging configuration; we also draw it ourselves
    # so the demo always shows something on stdout.
    printgraph(root);
    for acct in [root -->][?:Account] {
        for (edge_obj, target) in zip([edge acct ->:Owes:->], [acct ->:Owes:->]) {
            print(acct.owner, f"--{edge_obj.amount}-->" , target.owner);
        }
    }
}
