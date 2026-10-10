import from shed { ToolShed }

def stocked -> ToolShed {
    s = ToolShed(name="Elm St");
    s.register("drill", "Cordless drill");
    s.register("saw", "Mitre saw");
    s.register("ladder", "Step ladder");
    s.register("sander", "Orbital sander");
    return s;
}

test "register and checkout rules" {
    s = stocked();
    assert not s.register("drill", "Another drill");
    assert s.checkout("c1", "nope", 1, 7) == "unknown tool";
    assert s.checkout("c1", "drill", 1, 7) == "ok";
    assert s.checkout("c2", "drill", 1, 7) == "already lent";
    assert s.checkout("c1", "saw", 1, 7) == "ok";
    assert s.checkout("c1", "ladder", 1, 7) == "limit reached";
    assert s.checkout("c2", "ladder", 1, 7) == "ok";
    assert s.on_loan("c1") == ["drill", "saw"];
    assert s.on_loan("c2") == ["ladder"];
    assert len(s.on_loan("c9")) == 0;
}

test "returns, damage and repair" {
    s = stocked();
    assert not s.give_back("drill", False);
    s.checkout("c1", "drill", 1, 7);
    assert s.status("drill") == "lent";
    assert s.give_back("drill", True);
    assert not s.give_back("drill", False);
    assert s.status("drill") == "repair";
    assert s.checkout("c2", "drill", 2, 7) == "unavailable";
    assert len(s.on_loan("c1")) == 0;
    assert not s.repair("saw");
    assert s.repair("drill");
    assert not s.repair("drill");
    assert s.status("drill") == "available";
    assert s.checkout("c2", "drill", 2, 7) == "ok";
}

test "retiring tools" {
    s = stocked();
    s.checkout("c1", "saw", 1, 3);
    assert not s.retire("saw");
    assert s.retire("ladder");
    assert not s.retire("ladder");
    assert not s.retire("nope");
    assert s.status("ladder") == "retired";
    assert s.checkout("c1", "ladder", 1, 3) == "unavailable";
    assert s.status("nope") == "unknown";
    assert s.status("sander") == "available";
}

test "overdue loans ordered by due day then tool" {
    s = stocked();
    s.checkout("c1", "saw", 1, 5);
    s.checkout("c2", "drill", 3, 3);
    s.checkout("c2", "ladder", 0, 4);
    s.checkout("c3", "sander", 2, 20);
    assert len(s.overdue(4)) == 0;
    assert s.overdue(5) == ["c2:ladder"];
    assert s.overdue(7) == ["c2:ladder", "c2:drill", "c1:saw"];
    s.give_back("saw", False);
    assert s.overdue(7) == ["c2:ladder", "c2:drill"];
}

test "sheds keep their own tools and members" {
    a = stocked();
    b = ToolShed(name="Oak Rd", limit=1);
    assert b.register("drill", "Hammer drill");
    a.checkout("c1", "drill", 1, 7);
    assert b.status("drill") == "available";
    assert b.checkout("c1", "drill", 1, 7) == "ok";
    assert b.register("saw", "Jigsaw");
    assert b.checkout("c1", "saw", 1, 7) == "limit reached";
    assert a.on_loan("c1") == ["drill"];
}
