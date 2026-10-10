"""Recursive CTE demo: model a hierarchy (employee → manager → ... → CEO)
as a graph and have a walker traverse it from a leaf upward and back down,
mirroring the anchor + recursive-member semantics of WITH RECURSIVE over a
typed 'reports_to' edge."""

node Employee {
    has title: str = "";
    has level: int = 0;
}

edge ReportsTo: any --> any {
    has since: str = "";
}

walker ChainOfCommand {
    has visits: list[str] = [];
    has max_depth: int = 8;
    has depth: int = 0;

    can start with Root entry {
        visit [-->];
    }

    can ascend with Employee entry {
        self.visits.append(f"up[{self.depth}]: {here.title}");
        self.depth += 1;
        if self.depth > self.max_depth {
            self.visits.append("  (depth cap reached — anchor exhausted)");
        } else {
            visit [here ->:ReportsTo:->] else {
                self.visits.append("  (top of chain — anchor terminated)");
                disengage;
            }
        }
    }

    can descend with Employee entry {
        self.visits.append(f"down[{self.depth}]: {here.title}");
        self.depth += 1;
        if self.depth > self.max_depth {
            self.visits.append("  (depth cap reached — recursive member exhausted)");
        } else {
            visit [-->] else {
                self.visits.append("  (leaf reached — recursive member terminated)");
                disengage;
            }
        }
    }

    def `report() -> str {
        anchor_part = "WITH RECURSIVE chain (title, level) AS (\n";
        anchor_part += "  -- anchor member: leaf employee\n";
        anchor_part += "  SELECT title, level FROM employees WHERE id = :leaf_id\n";
        anchor_part += "  UNION ALL\n";
        anchor_part += "  -- recursive member: join on reports_to edge\n";
        anchor_part += "  SELECT e.title, e.level\n";
        anchor_part += "  FROM employees e\n";
        anchor_part += "  JOIN chain c ON e.id = c.manager_id\n";
        anchor_part += ") SELECT title, level FROM chain;\n";
        anchor_part += "-- SQLite 3.8.3+, MySQL 8.0+, PostgreSQL 11+ support this form";
        return anchor_part;
    }
}

with entry {
    ceo = Employee(title="CEO", level=5);
    vp_eng = Employee(title="VP-Eng", level=4);
    vp_sales = Employee(title="VP-Sales", level=4);
    mgr_backend = Employee(title="Mgr-Backend", level=3);
    mgr_frontend = Employee(title="Mgr-Frontend", level=3);
    mgr_smb = Employee(title="Mgr-SMB", level=3);
    eng_a = Employee(title="Eng-A", level=2);
    eng_b = Employee(title="Eng-B", level=2);
    sales_a = Employee(title="Sales-A", level=2);

    # Typed 'ReportsTo' edges carry the manager relationship.
    root +>:ReportsTo(since="2018"):+> ceo;
    ceo +>:ReportsTo(since="2019"):+> vp_eng;
    ceo +>:ReportsTo(since="2019"):+> vp_sales;
    vp_eng +>:ReportsTo(since="2020"):+> mgr_backend;
    vp_eng +>:ReportsTo(since="2020"):+> mgr_frontend;
    vp_sales +>:ReportsTo(since="2020"):+> mgr_smb;
    mgr_backend +>:ReportsTo(since="2021"):+> eng_a;
    mgr_backend +>:ReportsTo(since="2021"):+> eng_b;
    mgr_smb +>:ReportsTo(since="2021"):+> sales_a;

    # Anchor query: start at the leaf (Eng-A) and walk UP via ReportsTo.
    print("=== Recursive CTE — anchor at Eng-A, walking UP the chain ===");
    up_walker = ChainOfCommand(max_depth=6);
    up_walker spawn eng_a;
    print(f"Walker visits: {up_walker.visits}");
    print("\nEquivalent SQL the builder would emit for SQLite/MySQL 8+/PostgreSQL:");
    print(up_walker.report());

    # Recursive member: start at the CEO and walk DOWN through all reports.
    print("\n=== Recursive CTE — anchor at CEO, walking DOWN the org ===");
    down_walker = ChainOfCommand(max_depth=10);
    down_walker spawn ceo;
    print(f"Walker visits: {down_walker.visits}");
}
