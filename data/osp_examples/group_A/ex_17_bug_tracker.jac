"""Bug tracker: a connection hands back what it just created.

`here ++> Ticket(...)` evaluates to the freshly created ticket, so
the reporter walker can immediately grab its id and title without a
second lookup query.
"""

node Project {
    has name: str = "";
}

node Ticket {
    has title: str = "";
    has priority: str = "normal";
}

walker Reporter {
    has summary: str = "";
    has filed: int = 0;

    can start with Root entry {
        project = [-->][?:Project][0];
        print(f"Filing bugs against {project.name}");
        visit project;  # hand off to the Project ability exactly once
    }

    can file with Project entry {
        t1 = here ++> Ticket(title="Login page crashes on Safari", priority="high");
        print(f"Filed #{t1.title}: priority={t1.priority}");

        t2 = here ++> Ticket(title="Typo in footer");
        print(f"Filed #{t2.title}: priority={t2.priority}");

        self.filed = 2;
        self.summary = f"{self.filed} tickets filed";
        report self.summary;
    }
}

with entry {
    root ++> Project(name="Website Redesign");
    result = root spawn Reporter(summary="");
    print(f"Result: {result.reports}");
}
