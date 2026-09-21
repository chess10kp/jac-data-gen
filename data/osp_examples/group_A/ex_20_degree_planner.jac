"""Degree planning: capstone combining chains, co-requisites, and control flow.

The CS curriculum is built as one chained statement of PrereqOf
edges, with a lab course attached to its lecture by a bidirectional
Coreq edge. A planner walker skips already-completed courses,
announces co-requisite pairs found in both directions, and stops for
good once the capstone is scheduled.
"""

node Course {
    has code: str = "";
    has title: str = "";
    has credits: int = 3;
}

edge PrereqOf {
    has min_grade: str = "C";
}

edge Coreq { }

walker DegreePlanner {
    has student: str = "";
    has completed: list[str] = [];
    has total_credits: int = 0;
    has reports: list[str] = [];

    can start with Root entry {
        print(f"Planning semesters for {self.student}");
        visit [-->];
    }

    can plan with Course entry {
        # Queue the continuation before any early return.
        visit [-->];
        if here.code in self.completed {
            print(f"{here.code}: already completed, skipped");
            skip;
        }
        self.total_credits += here.credits;
        print(f"Scheduling {here.code} ({here.title}, {here.credits} cr)");

        # <+:Coreq:+> created edges in BOTH directions, so a plain
        # forward lookup finds the co-requisite from either course.
        partners = [->:Coreq:->];
        for lab in partners {
            print(f"  note: {here.code} meets together with {lab.code}");
        }

        if here.code == "CS-402" {
            report f"Capstone reached: {self.total_credits} credits planned";
            disengage;
        }
    }
}

with entry {
    cs101 = Course(code="CS-101", title="Intro to Programming");
    cs201 = Course(code="CS-201", title="Data Structures");
    lab = Course(code="CS-201L", title="Data Structures Lab", credits=1);
    cs301 = Course(code="CS-301", title="Algorithms");
    cs402 = Course(code="CS-402", title="Senior Capstone");

    # The whole prerequisite chain in one expression.
    root ++> cs101
        +>: PrereqOf(min_grade="B") :+> cs201
        +>: PrereqOf() :+> cs301
        +>: PrereqOf() :+> cs402;

    # Lecture and lab are linked in both directions.
    cs201 <+: Coreq() :+> lab;

    result = root spawn DegreePlanner(
        student="Priya",
        completed=["CS-101"]
    );
    print("---");
    for r in result.reports {
        print(r);
    }
}
