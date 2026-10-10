import from ferries { add_port, add_crossing, crossing_time, retime, quick_hops }

test "ports and crossings need known ends" {
    assert add_port("Oban");
    assert not add_port("Oban");
    assert add_port("Mull");
    assert add_crossing("Oban", "Mull", 45);
    assert not add_crossing("Oban", "Mull", 30);
    assert not add_crossing("Oban", "Iona", 60);
    assert crossing_time("Oban", "Mull") == 45;
    assert crossing_time("Oban", "Iona") == -1;
}

test "crossings are one-way" {
    add_port("Oban");
    add_port("Mull");
    add_crossing("Oban", "Mull", 45);
    assert crossing_time("Mull", "Oban") == -1;
    assert add_crossing("Mull", "Oban", 50);
    assert crossing_time("Mull", "Oban") == 50;
    assert crossing_time("Oban", "Mull") == 45;
}

test "retime changes only that crossing" {
    add_port("A");
    add_port("B");
    add_port("C");
    add_crossing("A", "B", 20);
    add_crossing("A", "C", 20);
    assert retime("A", "B", 35);
    assert not retime("B", "A", 10);
    assert crossing_time("A", "B") == 35;
    assert crossing_time("A", "C") == 20;
    assert crossing_time("B", "A") == -1;
}

test "quick hops under a limit" {
    for p in ["hub", "x", "y", "z", "w"] {
        add_port(p);
    }
    add_crossing("hub", "x", 15);
    add_crossing("hub", "y", 40);
    add_crossing("hub", "z", 25);
    add_crossing("x", "w", 5);
    assert quick_hops("hub", 25) == ["x", "z"];
    assert quick_hops("hub", 100) == ["x", "y", "z"];
    assert len(quick_hops("hub", 10)) == 0;
    assert len(quick_hops("nowhere", 100)) == 0;
    retime("hub", "y", 10);
    assert quick_hops("hub", 25) == ["x", "y", "z"];
}
