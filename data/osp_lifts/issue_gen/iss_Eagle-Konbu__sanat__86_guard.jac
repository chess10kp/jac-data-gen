"""Idiomatic OSP lift for Eagle-Konbu/sanat#86."""

node Statement {
    has kind: str;
    has label: str;
    has recursive: bool = False;
}

node CTE {
    has name: str;
    has columns: list[str];
    has materialized: str;
}

node Body {
    has kind: str;
}

edge HasCte {}
edge BodyOf {}
edge DependsOn {}

walker CteWalk {
    has claimed: dict[str, bool] = {};
    has names: list[str] = [];

    can collect_statement with Statement entry {
        print(here.label);
        for item in [here ->:HasCte:->][?:CTE] {
            visit :0: [item];
        }
    }

    can collect_cte with CTE entry {
        print(here.name);
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.names.append(here.name);
        for dep in [here ->:DependsOn:->][?:CTE] {
            visit :0: [dep];
        }
    }
}

walker BodyAudit {
    has ok: bool = True;

    can inspect_statement with Statement entry {
        print(here.label);
        if allowed_kind(here.kind) == False {
            self.ok = False;
        }
        for item in [here ->:HasCte:->][?:CTE] {
            visit :0: [item];
        }
    }

    can inspect_cte with CTE entry {
        print(here.name);
        if allowed_materialization(here.materialized) == False {
            self.ok = False;
        }
        for body in [here ->:BodyOf:->][?:Body] {
            visit :0: [body];
        }
    }

    can inspect_body with Body entry {
        print(here.kind);
        if allowed_kind(here.kind) == False {
            self.ok = False;
        }
    }
}

def allowed_kind(kind: str) -> bool {
    if kind == "select" {
        return True;
    }
    if kind == "insert" {
        return True;
    }
    if kind == "update" {
        return True;
    }
    if kind == "delete" {
        return True;
    }
    if kind == "set" {
        return True;
    }
    return False;
}

def allowed_materialization(materialized: str) -> bool {
    return materialized == "default"
        or materialized == "materialized"
        or materialized == "not_materialized";
}

def new_statement(kind: str, recursive: bool) -> Statement {
    return Statement(kind=kind, label=kind, recursive=recursive);
}

def find_cte(statement: Statement, name: str) -> CTE | None {
    for item in [statement ->:HasCte:->][?:CTE] {
        if item.name == name {
            return item;
        }
    }
    return None;
}

def add_cte(
    statement: Statement,
    name: str,
    columns: list[str],
    kind: str,
    materialized: str,
    dependencies: list[str]
) -> CTE {
    prior = find_cte(statement, name);
    if prior != None {
        return prior;
    }
    cte = CTE(
        name=name,
        columns=columns,
        materialized=materialized
    );
    body = Body(kind=kind);
    statement +>:HasCte:+> cte;
    cte +>:BodyOf:+> body;
    for dep_name in dependencies {
        dep = find_cte(statement, dep_name);
        if dep != None {
            cte +>:DependsOn:+> dep;
        }
    }
    return cte;
}

def cte_names(statement: Statement) -> list[str] {
    w = statement spawn CteWalk(claimed={});
    return sorted(w.names);
}

def validate_with(statement: Statement) -> bool {
    audit = statement spawn BodyAudit(ok=True);
    return audit.ok;
}

test "diamond revisit is claimed once" {
    stmt = new_statement("select", False);
    add_cte(stmt, "d", [], "select", "default", []);
    add_cte(stmt, "b", [], "select", "default", ["d"]);
    add_cte(stmt, "c", [], "select", "default", ["d"]);
    add_cte(stmt, "a", [], "select", "default", ["b", "c"]);
    assert (cte_names(stmt) == ["a", "b", "c", "d"]);
    assert (validate_with(stmt));
}

test "unknown dependency is tolerated" {
    stmt = new_statement("select", False);
    add_cte(stmt, "known", ["id"], "select", "default", ["missing"]);
    assert (find_cte(stmt, "missing") == None);
    assert (cte_names(stmt) == ["known"]);
}

test "dml body cte feeds another dml" {
    stmt = new_statement("insert", False);
    add_cte(stmt, "deleted", ["id"], "delete", "not_materialized", []);
    add_cte(stmt, "archived", [], "insert", "materialized", ["deleted"]);
    add_cte(stmt, "combined", [], "set", "default", ["archived"]);
    assert (validate_with(stmt));
    assert (cte_names(stmt) == ["archived", "combined", "deleted"]);
}

test "recursive self reference terminates" {
    stmt = new_statement("select", True);
    add_cte(stmt, "walk", ["id"], "select", "default", ["walk"]);
    assert (stmt.recursive);
    assert (cte_names(stmt) == ["walk"]);
    assert (validate_with(stmt));
}

test "unsupported body or materialization fails validation" {
    stmt = new_statement("merge", False);
    add_cte(stmt, "bad", [], "merge", "bogus", []);
    assert (validate_with(stmt) == False);
}
