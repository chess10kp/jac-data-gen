"""Bug tracker: file new tickets off a project and grab the fresh node back."""

node Project {
    has title: str = "";
    has version: str = "0.0.0";
}

node Ticket {
    has title: str = "";
    has priority: str = "low";
}

edge Filed {
    has at: str = "now";
}

walker FileTickets {
    can start with Root entry {
        visit [-->];
    }

    can file with Project entry {
        ticket1 = (here +>:Filed:+> Ticket(title="Login form crashes on submit", priority="high"));
        print(f"FILED: {ticket1.title} [{ticket1.priority}]");

        ticket2 = (here +>:Filed:+> Ticket(title="Typo on landing page", priority="low"));
        print(f"FILED: {ticket2.title} [{ticket2.priority}]");

        ticket3 = (here +>:Filed:+> Ticket(title="Payment timeout under load", priority="critical"));
        print(f"FILED: {ticket3.title} [{ticket3.priority}]");

        visit [-->];
    }
}

with entry {
    project = Project(title="WebApp", version="2.3.1");
    root ++> project;
    project spawn FileTickets();
}