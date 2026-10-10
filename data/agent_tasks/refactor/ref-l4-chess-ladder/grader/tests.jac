import from ladder { join, standings, challenge, record, head_to_head, withdraw, active_since }

def seed {
    for n in ["Ada", "Ben", "Cyd", "Dov", "Eli"] {
        join(n);
    }
}

test "joining appends at the bottom once" {
    assert join("Ada") == 1;
    assert join("Ben") == 2;
    assert join("Ada") == 0;
    assert join("Cyd") == 3;
    assert standings() == ["Ada", "Ben", "Cyd"];
}

test "challenge validation" {
    seed();
    assert challenge("Eli", "Zed", "win", 1) == "unknown player";
    assert challenge("Ben", "Ben", "win", 1) == "unknown player";
    assert challenge("Eli", "Ben", "resign", 1) == "bad outcome";
    assert challenge("Eli", "Ada", "win", 1) == "out of range";
    assert challenge("Ben", "Cyd", "win", 1) == "out of range";
    assert standings() == ["Ada", "Ben", "Cyd", "Dov", "Eli"];
    assert record("Eli") == [0, 0, 0];
}

test "a win takes the defender's rung, losses and draws do not move" {
    seed();
    assert challenge("Eli", "Ben", "win", 1) == "ok";
    assert standings() == ["Ada", "Eli", "Ben", "Cyd", "Dov"];
    assert challenge("Dov", "Ben", "draw", 2) == "ok";
    assert challenge("Cyd", "Eli", "loss", 2) == "ok";
    assert standings() == ["Ada", "Eli", "Ben", "Cyd", "Dov"];
    assert challenge("Dov", "Ben", "win", 3) == "ok";
    assert standings() == ["Ada", "Eli", "Dov", "Ben", "Cyd"];
}

test "records count both sides of each match" {
    seed();
    challenge("Eli", "Ben", "win", 1);
    challenge("Dov", "Ben", "draw", 2);
    challenge("Cyd", "Eli", "loss", 2);
    challenge("Ben", "Eli", "loss", 3);
    assert record("Eli") == [3, 0, 0];
    assert record("Ben") == [0, 2, 1];
    assert record("Cyd") == [0, 1, 0];
    assert record("Dov") == [0, 0, 1];
    assert record("Nobody") == [0, 0, 0];
}

test "head to head is per pair and per side" {
    seed();
    challenge("Eli", "Ben", "win", 1);
    challenge("Ben", "Eli", "win", 2);
    challenge("Eli", "Ben", "draw", 3);
    challenge("Dov", "Ben", "loss", 3);
    assert head_to_head("Eli", "Ben") == [1, 1, 1];
    assert head_to_head("Ben", "Dov") == [1, 0, 0];
    assert head_to_head("Ada", "Ben") == [0, 0, 0];
}

test "withdrawing closes the gap and drops history" {
    seed();
    challenge("Eli", "Ben", "win", 1);
    challenge("Dov", "Ben", "draw", 4);
    assert withdraw("Ben");
    assert not withdraw("Ben");
    assert standings() == ["Ada", "Eli", "Cyd", "Dov"];
    assert record("Eli") == [0, 0, 0];
    assert record("Dov") == [0, 0, 0];
    assert challenge("Dov", "Ada", "loss", 6) == "ok";
    assert join("Fay") == 5;
    assert challenge("Fay", "Eli", "win", 5) == "ok";
    assert standings() == ["Ada", "Fay", "Eli", "Cyd", "Dov"];
}

test "active since a round" {
    seed();
    challenge("Eli", "Ben", "win", 1);
    challenge("Dov", "Cyd", "draw", 3);
    challenge("Cyd", "Eli", "loss", 4);
    assert active_since(3) == ["Cyd", "Dov", "Eli"];
    assert active_since(4) == ["Cyd", "Eli"];
    assert active_since(1) == ["Ben", "Cyd", "Dov", "Eli"];
    assert len(active_since(5)) == 0;
}
