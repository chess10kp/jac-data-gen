import from hives { Hive, mark_queenless, requeen, record_loss, hive_label, needs_visit }

test "new hive is active" {
    h = Hive(tag="H1", brood_frames=6);
    assert hive_label(h) == "H1: active";
}

test "queen cycle" {
    h = Hive(tag="H2", brood_frames=5);
    assert not requeen(h);
    assert mark_queenless(h);
    assert hive_label(h) == "H2: queenless";
    assert not mark_queenless(h);
    assert requeen(h);
    assert hive_label(h) == "H2: requeened";
    assert not requeen(h);
    assert mark_queenless(h);
    assert hive_label(h) == "H2: queenless";
}

test "lost is terminal" {
    a = Hive(tag="A", brood_frames=4);
    b = Hive(tag="B", brood_frames=4);
    mark_queenless(b);
    assert record_loss(a);
    assert record_loss(b);
    assert not record_loss(a);
    assert hive_label(a) == "A: lost";
    assert not mark_queenless(a);
    assert not requeen(b);
    assert hive_label(b) == "B: lost";
}

test "which hives need a visit" {
    ok = Hive(tag="ok", brood_frames=8);
    weak = Hive(tag="weak", brood_frames=2);
    q = Hive(tag="q", brood_frames=9);
    rq = Hive(tag="rq", brood_frames=1);
    gone = Hive(tag="gone", brood_frames=0);
    mark_queenless(q);
    mark_queenless(rq);
    requeen(rq);
    record_loss(gone);
    assert needs_visit([ok, weak, q, rq, gone]) == ["q", "rq", "weak"];
    assert len(needs_visit([ok, gone])) == 0;
}
