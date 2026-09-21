"""Cascade deletion: remove a project together with all of its tasks.

Collect references to the whole subtree BEFORE deleting (del detaches
edges mid-traversal), then purge them in one pass at Root exit.
"""

node Project {
    has name: str;
}

edge Contains { }

node Task {
    has title: str;
    has done: bool = False;
}

walker add_project {
    has name: str;
    has tasks: list[str];

    can build with Root entry {
        proj = here ++> Project(name=self.name);
        for t in self.tasks {
            proj +>: Contains() :+> Task(title=t);
        }
        report {"project": jid(proj)};
    }
}

walker:priv delete_project {
    has project_id: str;
    has doomed: list[any] = [];

    can find with Root entry {
        visit [-->][?:Project];  # projects hang off root via generic edges
    }

    can gather with Project entry {
        if jid(here) == self.project_id {
            self.doomed.append(here);
            # Snapshot children BEFORE any deletion detaches the edges.
            for child in [->:Contains:->] {
                self.doomed.append(child);
            }
            skip;  # stop this ability; deletion happens at exit
        }
    }

    can purge with Root exit {
        # `del` on each node also detaches its incident Contains edges.
        removed = [jid(n) for n in self.doomed];
        for n in self.doomed {
            del n;
        }
        report {"cascade_deleted": len(removed), "ids": removed};
    }
}

walker dump {
    can show with Root entry {
        for p in [-->][?:Project] {
            kids = [t.title for t in [p ->:Contains:->]];
            report {"project": p.name, "tasks": kids};
        }
    }
}

with entry {
    r = root spawn add_project(name="spring cleaning", tasks=["garage", "gutters"]);
    pid = r.reports[0]["project"];
    root spawn add_project(name="keep me", tasks=["do not touch"]);

    before = root spawn dump();
    print("before:", before.reports);

    root spawn delete_project(project_id=pid);

    after = root spawn dump();
    print("after :", after.reports);
}
