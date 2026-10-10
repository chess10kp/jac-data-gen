"""Bug tracker: file tickets off a project and capture the connection result.

Demonstrates the `root ++> (t := Ticket(...))` grouped-creation form so the
new ticket is bound in a single expression, then a walker reads back its
title and priority without a separate lookup.
"""

node Project {
    has name: str = "";
}

node Ticket {
    has title: str = "";
    has priority: str = "low";
    has available: bool = True;
}

walker Triage {
    can start with Root entry {
        visit [-->];
    }

    can review with Project entry {
        print(f"Project: {here.name}");
        visit [-->];
    }

    can file with Ticket entry {
        status = "OPEN" if here.available else "CLOSED";
        print(f"[{status}] {here.title} | priority={here.priority}");
        visit [-->] else {
            disengage;
        }
    }
}

with entry {
    root ++> Project(name="Phoenix");
    (root ++> Ticket(title="Login loop on Safari", priority="high"))[0];
    fresh = (root ++> Ticket(title="CSV export broken", priority="medium"))[0];
    (root ++> Ticket(title="Typo on landing page", priority="low", available=False))[0];

    print(f"Captured fresh ticket: {fresh.title} ({fresh.priority})");
    print("--- Walking the tracker ---");
    root spawn Triage();
}