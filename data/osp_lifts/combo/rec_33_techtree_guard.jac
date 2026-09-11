"""Guard suite for rec_33_techtree."""
import from rec_33_techtree { TechTree }

def fresh() -> TechTree {
    t = TechTree();
    t.add_branch("empire");
    t.add_branch("military", parent="empire");
    t.add_branch("economy", parent="empire");
    t.add_tech("swords", "military", 1);
    t.add_tech("armor", "military", 2);
    t.add_tech("mining", "economy", 1);
    t.add_tech("currency", "economy", 2);
    t.require("armor", "swords");
    t.require("currency", "mining");
    return t;
}

test "subtree tech multiset" {
    t = fresh();
    assert t.subtree_techs("empire") == ["armor", "currency", "mining", "swords"];
    assert t.subtree_techs("economy") == ["currency", "mining"];
    assert t.subtree_techs("military") == ["armor", "swords"];
}

test "prereq planning" {
    t = fresh();
    assert t.remaining_prereqs(set(), "armor") == ["swords"];
    assert t.remaining_prereqs({"swords"}, "armor") == [];
    assert t.can_research({"swords"}, "armor");
    assert not t.can_research(set(), "armor");
    assert t.era_of("currency") == 2;
}

test "transitive chain" {
    t = fresh();
    t.add_tech("gunpowder", "military", 3);
    t.require("gunpowder", "armor");
    assert t.remaining_prereqs({"swords"}, "gunpowder") == ["armor"];
    assert t.remaining_prereqs(set(), "gunpowder") == ["armor", "swords"];
}

test "prereq cycle terminates" {
    t = fresh();
    t.add_tech("gunpowder", "military", 3);
    t.require("gunpowder", "armor");
    t.require("swords", "gunpowder");  # cycle
    got = t.remaining_prereqs(set(), "gunpowder");
    assert len(got) == len(set(got));  # once-only per tech
    assert got == ["armor", "swords"];
}

test "shared prerequisite collected once (diamond)" {
    t = fresh();
    t.add_tech("siege", "military", 3);
    t.require("siege", "mining");
    t.require("siege", "currency");  # both reach mining? currency->mining yes
    got = t.remaining_prereqs(set(), "siege");
    assert len(got) == len(set(got));
    assert got == ["currency", "mining"];
}

test "duplicate branch and unknown branch raise" {
    t = fresh();
    threw_dup = False;
    try {
        t.add_branch("empire");
    } except ValueError as ex {
        threw_dup = True;
    }
    assert threw_dup;
    threw_missing = False;
    try {
        t.add_tech("x", "ghost", 1);
    } except KeyError as ex {
        threw_missing = True;
    }
    assert threw_missing;
}
