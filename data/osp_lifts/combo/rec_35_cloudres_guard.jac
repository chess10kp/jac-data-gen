"""Guard suite for rec_35_cloudres."""
import from rec_35_cloudres { CloudManager, DependsOn }

def fresh() -> CloudManager {
    m = CloudManager();
    m.add_resource("stack", cost=0);
    m.add_resource("net", parent="stack", cost=10);
    m.add_resource("db", parent="stack", cost=30);
    m.add_resource("replica", parent="db", cost=20);
    m.add_resource("app", parent="stack", cost=15);
    return m;
}

test "aggregates maintained incrementally" {
    m = fresh();
    assert m.aggregate("stack") == 75;
    assert m.aggregate("db") == 50;
    assert m.ancestors("replica") == ["db", "stack"];
    threw = False;
    try {
        m.add_resource("net", cost=1);
    } except ValueError as ex {
        threw = True;
    }
    assert threw;
}

test "dependency closure multiset" {
    m = fresh();
    m.attach_dependency("app", "db");
    m.attach_dependency("app", "net");
    m.attach_dependency("db", "net");
    assert m.dependency_closure("app") == ["db", "net"];
    assert m.dependency_closure("net") == [];
}

test "cascade delete recomputes ancestors" {
    m = fresh();
    doomed = m.delete("db");
    assert doomed == ["db", "replica"];
    assert m.aggregate("stack") == 25;
    assert "db" not in m.by_id and "replica" not in m.by_id;
    # postcondition: no live resource keeps edges into the dead set
    assert len([m.by_id["app"] ->:DependsOn:->]) == 0;
    assert m.ancestors("app") == ["stack"];
}

test "external dependency blocks cascade, refusal is non-mutating" {
    m = fresh();
    m.attach_dependency("app", "replica");
    threw = False;
    try {
        m.delete("db");
    } except ValueError as ex {
        threw = True;
    }
    assert threw;
    m.attach_dependency("replica", "net");  # internal-only, does not unblock
    threw2 = False;
    try {
        m.delete("db");
    } except ValueError as ex {
        threw2 = True;
    }
    assert threw2;
    assert m.aggregate("stack") == 75;
    assert sorted(m.by_id.keys()) == ["app", "db", "net", "replica", "stack"];
}

test "shared descendant deleted once only (diamond)" {
    m = CloudManager();
    m.add_resource("root", cost=0);
    m.add_resource("l1", parent="root", cost=1);
    m.add_resource("r1", parent="root", cost=1);
    # diamond over the hierarchy is impossible (tree), so exercise the
    # dependency graph instead: both l1 and r1 depend on shared
    m.add_resource("shared", parent="root", cost=5);
    m.attach_dependency("l1", "shared");
    m.attach_dependency("r1", "shared");
    doomed = m.delete("root");
    assert len(doomed) == len(set(doomed));
    assert doomed == ["l1", "r1", "root", "shared"];
}

test "dependency cycle terminates closure walk" {
    m = fresh();
    m.attach_dependency("net", "app");
    m.attach_dependency("app", "net");  # cycle
    got = m.dependency_closure("app");
    assert len(got) == len(set(got));
    assert sorted(got) == ["net"];
}
