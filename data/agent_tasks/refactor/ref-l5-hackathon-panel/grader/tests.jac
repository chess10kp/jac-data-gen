import from main { register_team, add_judge, assign, score, team_score, leaderboard, pending }

def setup {
    register_team("owls", "ai");
    register_team("bees", "ai");
    register_team("cats", "web");
    add_judge("ann");
    add_judge("bob");
    assign("ann", "ai");
    assign("bob", "ai");
    assign("bob", "web");
}

test "registration and assignment" {
    assert register_team("owls", "ai");
    assert not register_team("owls", "web");
    assert add_judge("ann");
    assert not add_judge("ann");
    assert assign("ann", "ai");
    assert assign("ann", "ai");
    assert not assign("ann", "nope");
    assert not assign("zed", "ai");
    assert pending("ann") == ["owls"];
    assert len(pending("zed")) == 0;
}

test "score validation" {
    setup();
    assert score("zed", "owls", "craft", 5) == "unknown judge";
    assert score("ann", "nope", "craft", 5) == "unknown team";
    assert score("ann", "cats", "craft", 5) == "not assigned";
    assert score("ann", "owls", "style", 5) == "bad criterion";
    assert score("ann", "owls", "craft", 11) == "bad points";
    assert score("ann", "owls", "craft", 0) == "bad points";
    assert score("bob", "cats", "demo", 10) == "ok";
    assert team_score("cats") == 10.0;
    assert team_score("owls") == 0.0;
    assert team_score("nope") == 0.0;
}

test "averages per judge and rescoring replaces" {
    setup();
    score("ann", "owls", "impact", 8);
    score("ann", "owls", "craft", 6);
    score("bob", "owls", "impact", 5);
    assert team_score("owls") == 9.5;
    score("ann", "owls", "craft", 9);
    assert team_score("owls") == 11.0;
    score("bob", "owls", "demo", 2);
    assert team_score("owls") == 12.0;
    score("ann", "bees", "demo", 7);
    assert team_score("bees") == 7.0;
}

test "leaderboard ordering and track filter" {
    setup();
    register_team("ants", "ai");
    score("ann", "owls", "impact", 6);
    score("ann", "bees", "impact", 9);
    score("bob", "cats", "craft", 9);
    score("ann", "ants", "impact", 6);
    assert leaderboard("ai") == ["bees", "ants", "owls"];
    assert leaderboard("web") == ["cats"];
    assert leaderboard("") == ["bees", "cats", "ants", "owls"];
    assert len(leaderboard("mobile")) == 0;
}

test "pending lists teams a judge still owes" {
    setup();
    assert pending("bob") == ["bees", "cats", "owls"];
    score("bob", "owls", "impact", 3);
    score("bob", "owls", "craft", 3);
    score("bob", "owls", "craft", 4);
    assert pending("bob") == ["bees", "cats", "owls"];
    score("bob", "owls", "demo", 3);
    assert pending("bob") == ["bees", "cats"];
    assert pending("ann") == ["bees", "owls"];
}
