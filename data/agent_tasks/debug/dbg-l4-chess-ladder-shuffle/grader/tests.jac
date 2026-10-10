import from ladder { Player, join, player }
import from matches { Played, MatchResult }
import from challenge { RecordMatch, Standings, HeadToHead }

def club(names: list[str]) {
    for n in names {
        join(n);
    }
}

def must(name: str) -> Player {
    return [p for p in [root -->[?:Player]] if p.name == name][0];
}

def ladder_now -> list[str] {
    return (root spawn Standings()).reports[0];
}

def play(c: str, d: str, won: bool, rnd: int) -> MatchResult {
    return (root spawn RecordMatch(challenger=c, defender=d, challenger_won=won, round=rnd)).reports[0];
}

test "standings in join order" {
    club(["A", "B", "C"]);
    assert ladder_now() == ["A", "B", "C"];
}

test "winning challenger takes the rank and others shift down" {
    club(["A", "B", "C", "D", "E"]);
    r = play("E", "B", True, 1);
    assert r.ok == True;
    assert r.new_rank == 2;
    assert ladder_now() == ["A", "E", "B", "C", "D"];
    assert sorted([p.rank for p in [root -->[?:Player]]]) == [1, 2, 3, 4, 5];
}

test "losing challenge records but changes nothing" {
    club(["A", "B", "C"]);
    r = play("C", "A", False, 1);
    assert r.ok == True;
    assert r.new_rank == 3;
    assert ladder_now() == ["A", "B", "C"];
    c = must("C");
    assert len([c ->:Played:->]) == 1;
}

test "range rules" {
    club(["A", "B", "C", "D", "E"]);
    far = play("E", "A", True, 1);
    assert far.ok == False;
    assert far.reason == "out of range";
    down = play("A", "B", True, 1);
    assert down.reason == "out of range";
    same = play("C", "C", True, 1);
    assert same.reason == "out of range";
    assert ladder_now() == ["A", "B", "C", "D", "E"];
    for n in ["A", "C", "E"] {
        assert len([must(n) ->:Played:->]) == 0;
    }
    edge_ok = play("D", "A", True, 2);
    assert edge_ok.ok == True;
    assert ladder_now() == ["D", "A", "B", "C", "E"];
}

test "unknown players" {
    club(["A", "B"]);
    assert play("Z", "A", True, 1).reason == "unknown player";
    assert play("B", "Q", True, 1).reason == "unknown player";
}

test "head to head counts both directions" {
    club(["A", "B", "C"]);
    play("B", "A", False, 1);
    play("B", "A", True, 2);
    play("A", "B", True, 3);
    play("C", "B", False, 4);
    h = (root spawn HeadToHead(a="A", b="B")).reports[0];
    assert h == {"A": 2, "B": 1};
    h2 = (root spawn HeadToHead(a="C", b="A")).reports[0];
    assert h2 == {"C": 0, "A": 0};
}
