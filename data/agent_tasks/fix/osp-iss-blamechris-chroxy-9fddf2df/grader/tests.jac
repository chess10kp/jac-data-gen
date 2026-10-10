import from main { ForkOf, Indexer, LiveAppend, NextTurn, OwnedBy, Query, Session, Turn }
test "indexer follows session and fork relationships" {
    main = Session(title="main", project="alpha", provider="openai", started_at=1);
    forked = Session(title="fork-A", project="alpha", provider="openai", started_at=2);
    root +>:OwnedBy:+> main;
    main +>:ForkOf:+> forked;

    m1 = Turn(role="user", content="main request", at=10);
    f1 = Turn(role="assistant", content="fork response", at=20);
    main +>:NextTurn:+> m1;
    forked +>:NextTurn:+> f1;

    idx = Indexer();
    root spawn idx;

    assert len(idx.indexed) == 4, f"indexed entries={idx.indexed}";
    assert ("SESSION", "main") in idx.indexed, f"missing main={idx.indexed}";
    assert ("SESSION", "fork-A") in idx.indexed, f"missing fork={idx.indexed}";
    assert ("TURN", "user", "main request") in idx.indexed, f"missing main turn={idx.indexed}";
    assert ("TURN", "assistant", "fork response") in idx.indexed, f"missing fork turn={idx.indexed}";
}

test "query matches case-insensitively and filters by role" {
    session = Session(title="search", project="alpha", provider="openai", started_at=1);
    root +>:OwnedBy:+> session;

    first = Turn(role="user", content="Needle in the request", at=10);
    second = Turn(role="assistant", content="NEEDLE in the response", at=11);
    third = Turn(role="user", content="unrelated text", at=12);
    session +>:NextTurn:+> first +>:NextTurn:+> second +>:NextTurn:+> third;

    q = Query(needle="needle", role_filter="assistant");
    root spawn q;

    assert len(q.hits) == 1, f"query hits={q.hits}";
    assert ("assistant", "NEEDLE in the response") in q.hits, f"unexpected hits={q.hits}";
}

test "newly appended turn is immediately searchable" {
    session = Session(title="live", project="alpha", provider="openai", started_at=1);
    root +>:OwnedBy:+> session;

    session spawn LiveAppend();

    turns = [session ->:NextTurn:->];
    assert len(turns) == 1, f"live turn count={len(turns)}";

    q = Query(needle="APPENDED", role_filter="user");
    root spawn q;

    assert len(q.hits) == 1, f"live query hits={q.hits}";
    assert ("user", "just appended") in q.hits, f"missing live hit={q.hits}";
}
