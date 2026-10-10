import from tramway { Stop, Track, stop, add_hop, RunLine, Interchanges }

test "stop is get-or-create" {
    a = stop("Harbour");
    b = stop("Harbour");
    assert a == b;
    assert len([root -->[?:Stop]]) == 1;
}

test "add_hop creates a timed track for a line" {
    add_hop("7", "X", "Y", 6);
    tracks = [edge stop("X") ->:Track:->];
    assert len(tracks) == 1;
    assert tracks[0].line == "7";
    assert tracks[0].minutes == 6;
    assert [s.name for s in [stop("X") ->:Track:->]] == ["Y"];
}

test "single stop line reports just the start" {
    stop("Lonely");
    w = stop("Lonely") spawn RunLine(line="1");
    assert len(w.reports) == 1;
    assert w.reports[0] == ["Lonely"];
    assert w.minutes == 0;
}

test "rides to the terminus summing minutes" {
    add_hop("4", "A", "B", 2);
    add_hop("4", "B", "C", 5);
    add_hop("4", "C", "D", 1);
    w = stop("A") spawn RunLine(line="4");
    assert w.reports[0] == ["A", "B", "C", "D"];
    assert w.minutes == 8;
    assert len(w.reports) == 1;
}

test "rides only forward from a middle stop" {
    add_hop("4", "A", "B", 2);
    add_hop("4", "B", "C", 5);
    w = stop("B") spawn RunLine(line="4");
    assert w.reports[0] == ["B", "C"];
    assert w.minutes == 5;
}

test "other lines at a branch are ignored" {
    add_hop("1", "Hub", "North", 3);
    add_hop("2", "Hub", "South", 9);
    add_hop("1", "North", "End", 4);
    w = stop("Hub") spawn RunLine(line="1");
    assert w.reports[0] == ["Hub", "North", "End"];
    assert w.minutes == 7;
    w2 = stop("Hub") spawn RunLine(line="2");
    assert w2.reports[0] == ["Hub", "South"];
    assert w2.minutes == 9;
}

test "loop stops at the start and does not count the closing hop" {
    add_hop("L", "P", "Q", 3);
    add_hop("L", "Q", "R", 4);
    add_hop("L", "R", "P", 20);
    w = stop("P") spawn RunLine(line="L");
    assert w.reports[0] == ["P", "Q", "R"];
    assert w.minutes == 7;
}

test "line that does not exist goes nowhere" {
    add_hop("1", "A", "B", 2);
    w = stop("A") spawn RunLine(line="99");
    assert w.reports[0] == ["A"];
    assert w.minutes == 0;
}

test "no stops means no interchanges" {
    w = root spawn Interchanges();
    assert len(w.reports) == 1;
    assert len(w.reports[0]) == 0;
}

test "a single line has no interchanges" {
    add_hop("1", "A", "B", 1);
    add_hop("1", "B", "C", 1);
    assert len((root spawn Interchanges()).reports[0]) == 0;
}

test "two departing lines make an interchange" {
    add_hop("1", "Hub", "N", 1);
    add_hop("2", "Hub", "S", 1);
    assert (root spawn Interchanges()).reports[0] == ["Hub"];
}

test "two arriving lines make an interchange" {
    add_hop("1", "N", "Hub", 1);
    add_hop("2", "S", "Hub", 1);
    assert (root spawn Interchanges()).reports[0] == ["Hub"];
}

test "arriving plus departing lines count and output is sorted" {
    add_hop("1", "Mid", "Zed", 1);
    add_hop("2", "Top", "Mid", 1);
    add_hop("1", "Ant", "Bee", 1);
    add_hop("3", "Cat", "Ant", 1);
    w = root spawn Interchanges();
    assert w.reports[0] == ["Ant", "Mid"];
    assert w.hubs == ["Mid", "Ant"] or w.hubs == ["Ant", "Mid"];
}
