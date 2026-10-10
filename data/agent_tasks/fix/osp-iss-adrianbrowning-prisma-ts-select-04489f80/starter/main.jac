"""Recursive CTE builder for a typed organization hierarchy.

Models the core scenario from issue #162: composing an anchor query with a
recursive member using UNION ALL semantics over a typed parent/child graph
of employees. The walker descends the reports chain exactly the way a
WITH RECURSIVE CTE would, accumulating depth and cycle-safe traversal
state. The column types emitted by the builder mirror the typed `has`
fields on the node archetypes.
"""

node Employee {
    has id: int = 0;
    has title: str = "";
    has department: str = "";
}

edge ReportsTo {
    has since: str = "";
}

walker RecursiveCTE {
    has anchor_id: int = 0;
    has max_depth: int = 0;
    has depth: int = 0;
    has visited: list[int] = [];
    has rows: list[dict] = [];

    can start with Root entry {
        print(f"WITH RECURSIVE org_tree AS (");
        print(f"  -- anchor: row at depth 0");
        self.rows.append({"id": 0, "title": "", "department": "", "depth": 0});
        visit [->:ReportsTo:->];
    }

    can descend with Employee entry {
        if here.id in self.visited {
            disengage;
        }
        if self.max_depth > 0 and self.depth >= self.max_depth {
            disengage;
        }
        next_depth = self.depth + 1;
        self.visited.append(here.id);
        self.rows.append({
            "id": here.id,
            "title": here.title,
            "department": here.department,
            "depth": next_depth,
        });
        print(f"  -- recursive member: depth {next_depth} UNION ALL");
        self.depth = next_depth;
        visit [->:ReportsTo:->];
    }
}

with entry {
    ceo = Employee(id=1, title="CEO", department="Exec");
    vp_eng = Employee(id=2, title="VP Engineering", department="Eng");
    vp_sales = Employee(id=3, title="VP Sales", department="Sales");
    eng_lead = Employee(id=4, title="Eng Lead", department="Eng");
    ic1 = Employee(id=5, title="IC1", department="Eng");
    ic2 = Employee(id=6, title="IC2", department="Eng");
    rep1 = Employee(id=7, title="AE1", department="Sales");

    ceo +>:ReportsTo(since="2018-01-01"):+> vp_eng;
    ceo +>:ReportsTo(since="2018-01-01"):+> vp_sales;
    vp_eng +>:ReportsTo(since="2019-03-15"):+> eng_lead;
    eng_lead +>:ReportsTo(since="2020-06-01"):+> ic1;
    eng_lead +>:ReportsTo(since="2020-06-01"):+> ic2;
    vp_sales +>:ReportsTo(since="2019-09-10"):+> rep1;

    builder = RecursiveCTE(anchor_id=1, max_depth=10, depth=0);
    print(f"SELECT id, title, department, depth FROM org_tree;");
    print(f"-- target dialects: SQLite, MySQL 8+, PostgreSQL");
    ceo spawn builder;

    print(f"-- emitted rows ({len(builder.rows)} total):");
    for row in builder.rows {
        print(f"  {row}");
    }
}