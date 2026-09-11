"""Guard suite for rec_32_refengine."""
import from rec_32_refengine { RefactorEngine }

def fresh() -> RefactorEngine {
    e = RefactorEngine();
    e.add_scope("mod");
    e.add_scope("cls", parent="mod");
    e.add_scope("meth", parent="cls");
    e.add_scope("func", parent="mod");
    e.define("mod", "config");
    e.define("cls", "config");
    e.define("func", "helper");
    e.add_reference("meth", "config");
    e.add_reference("func", "config");
    e.add_reference("mod", "helper");
    return e;
}

test "definitions multiset" {
    e = fresh();
    assert e.definitions("config") == ["cls", "mod"];
    assert e.definitions("ghost") == [];
}

test "resolve nearest enclosing definition" {
    e = fresh();
    assert e.resolve("meth", "config") == "cls";
    assert e.resolve("func", "config") == "mod";
    assert e.resolve("meth", "helper") is None;  # func is a sibling, not an ancestor
    assert e.resolve("mod", "missing") is None;
}

test "references within subtree" {
    e = fresh();
    assert e.references_within("mod", "config") == ["func", "meth"];
    assert e.references_within("cls", "config") == ["meth"];
    assert e.references_within("func", "config") == ["func"];  # root itself counts
}

test "rename rewires definitions and references" {
    e = fresh();
    n = e.rename("helper", "util_fn");
    assert n == 1;
    assert e.definitions("util_fn") == ["func"];
    assert e.definitions("helper") == [];
    assert e.resolve("func", "util_fn") == "func";
    # postcondition: no dangling edges to the old symbol
    e.add_reference("meth", "util_fn");
    assert e.references_within("mod", "util_fn") == ["meth", "mod"];
}

test "rename collision and unknown raise" {
    e = fresh();
    threw_collision = False;
    try {
        e.rename("helper", "config");
    } except ValueError as ex {
        threw_collision = True;
    }
    assert threw_collision;
    threw_missing = False;
    try {
        e.rename("ghost", "whatever2");
    } except KeyError as ex {
        threw_missing = True;
    }
    assert threw_missing;
    assert e.rename("helper", "helper") == 0;
}

test "duplicate scope rejected" {
    e = fresh();
    threw = False;
    try {
        e.add_scope("mod");
    } except ValueError as ex {
        threw = True;
    }
    assert threw;
}
