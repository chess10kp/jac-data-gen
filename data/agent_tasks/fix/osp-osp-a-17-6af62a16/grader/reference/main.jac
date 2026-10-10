"""Bug tracker: tickets hang off a project node.

Demonstrates the grouped-creation idiom ``root ++> (t := Ticket(...))``
which both creates the node AND captures a handle to it in one expression,
so the freshly filed ticket can be reported immediately without a lookup.
"""

node Ticket {
    has title: str = "";
    has priority: str = "low";
    has available: bool = True;
}

node Project {
    has name: str = "";
}

walker Triage {
    can start with Root entry {
        visit [-->];
    }

    can review with Project entry {
        print(f"Project: {here.name}");
        visit [-->];
    }

    can log with Ticket entry {
        status = "OPEN" if here.available else "CLOSED";
        print(f"  [{status}] {here.title} (priority={here.priority})");
    }
}

with entry {
    proj = Project(name="Jac Compiler");
    root ++> proj;

    # Connect-and-grab in a single expression: build the ticket, attach it
    # to the project, AND bind the new node to `fresh` all at once.
    proj ++> (fresh := Ticket(title="Walker cycle guard hangs", priority="high"));
    proj ++> (stale := Ticket(title="Typo in docs", priority="low", available=False));

    # No lookup query needed: `fresh` already references the just-attached node.
    print(f"Just filed: {fresh.title} (priority={fresh.priority})");

    root spawn Triage();
}
