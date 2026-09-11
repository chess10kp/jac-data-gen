"""Guard suite for rec_34_social."""
import from rec_34_social { SocialNetwork }

def fixture() -> SocialNetwork {
    n = SocialNetwork();
    n.add_community("site");
    n.add_community("gaming", parent="site");
    n.add_community("retro", parent="gaming");
    n.add_community("news", parent="site");
    n.join("ann", "retro");
    n.join("bob", "retro");
    n.join("cy", "gaming");
    n.join("dee", "news");
    return n;
}

test "community structure" {
    n = fixture();
    assert sorted([n.by_cid[c].cid for c in n.by_cid]) == ["gaming", "news", "retro", "site"];
    threw = False;
    try {
        n.add_community("site");
    } except ValueError as ex {
        threw = True;
    }
    assert threw;
    threw_missing = False;
    try {
        n.join("eve", "ghost");
    } except KeyError as ex {
        threw_missing = True;
    }
    assert threw_missing;
}

test "members across nested communities" {
    n = fixture();
    assert n.members_within("retro") == ["ann", "bob"];
    assert n.members_within("gaming") == ["ann", "bob", "cy"];
    assert n.members_within("gaming", include_sub=False) == ["cy"];
    assert n.members_within("site") == ["ann", "bob", "cy", "dee"];
}

test "join dedups and follow requires prior join" {
    n = fixture();
    n.join("ann", "retro");  # repeat membership: no-op
    assert n.members_within("retro") == ["ann", "bob"];
    threw = False;
    try {
        n.follow("newguy", "bob");  # never joined: source raises KeyError
    } except KeyError as ex {
        threw = True;
    }
    assert threw;
}

test "circle cap matches source <= max_size-1 others semantics" {
    n = fixture();
    n.join("fin", "news");  # both ends must have joined
    n.follow("ann", "bob");
    n.follow("bob", "cy");
    n.follow("cy", "dee");
    n.follow("dee", "fin");
    # max_size counts the origin: at most max_size-1 others collected
    got = n.circle("ann", max_size=3);
    assert len(got) <= 2, got;
    assert len(got) == 2, got;  # BFS saturates the budget
    assert n.circle("ann", max_size=1) == [];
    assert "ann" not in got;
    full = n.circle("ann");
    assert sorted(full) == ["bob", "cy", "dee", "fin"], full;
}

test "block propagation severs follows both ways" {
    n = fixture();
    n.follow("ann", "bob");
    n.follow("bob", "ann");
    assert n.circle("ann") == ["bob"];
    n.block("ann", "bob");
    assert n.circle("ann") == [];
    assert n.common_follows("ann", "bob") == [];
    threw = False;
    try {
        n.follow("ann", "bob");
    } except ValueError as ex {
        threw = True;
    }
    assert threw;
}

test "follow circle with cycle and diamond" {
    n = fixture();
    n.follow("ann", "bob");
    n.follow("bob", "cy");
    n.follow("cy", "dee");
    assert n.circle("ann") == ["bob", "cy", "dee"];
    n.follow("dee", "ann");  # cycle
    assert n.circle("ann") == ["bob", "cy", "dee"];
    m = fixture();
    m.follow("ann", "bob");
    m.follow("ann", "cy");
    m.follow("bob", "dee");
    m.follow("cy", "dee");  # diamond
    got = m.circle("ann");
    assert len(got) == len(set(got));
    assert got == ["bob", "cy", "dee"];
}

test "common follows multiset" {
    n = fixture();
    n.follow("ann", "cy");
    n.follow("bob", "cy");
    n.follow("ann", "dee");
    assert n.common_follows("ann", "bob") == ["cy"];
}
