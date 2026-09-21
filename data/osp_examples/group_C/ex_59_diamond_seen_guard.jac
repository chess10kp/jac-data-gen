"""Count every build task in a dependency DAG that contains diamonds.

Shared libraries are depended on by several modules, so the graph has
diamonds: a single query deduplicates destinations, but separate visit
steps can still enqueue the same node twice. The auditor guards with a
seen-set keyed on jid so each task is counted exactly once.
"""

node Task {
    has name: str;
    has minutes: int;
}

edge Needs {}

walker Auditor {
    has seen: set = set();
    has total_minutes: int = 0;
    has double_enqueue_avoided: bool = False;

    can start with Root entry {
        visit [-->];
    }

    can audit with Task entry {
        # Diamond in the DAG: this node may already have been enqueued
        # from two different parents -- count it once
        if jid(here) in self.seen {
            print(f"{here.name}: already audited via another path, skipping");
            self.double_enqueue_avoided = True;
            skip;   # return from this ability only
        }
        self.seen.add(jid(here));
        self.total_minutes += here.minutes;
        print(f"auditing {here.name} ({here.minutes} min, running total {self.total_minutes})");

        visit [->:Needs:->];
    }

    can finish with Root exit {
        print(f"-- Audit: {len(self.seen)} unique task(s), total {self.total_minutes} min --");
        if self.double_enqueue_avoided {
            print("Seen-guard caught at least one diamond re-entry");
        }
    }
}

with entry {
    app = Task(name="build-app", minutes=5);
    web = Task(name="compile-web", minutes=8);
    api = Task(name="compile-api", minutes=12);
    core = Task(name="link-core", minutes=20);   # shared by web and api

    root ++> app;
    app +>: Needs() :+> web;
    app +>: Needs() :+> api;
    web +>: Needs() :+> core;
    api +>: Needs() :+> core;

    root spawn Auditor();
}
