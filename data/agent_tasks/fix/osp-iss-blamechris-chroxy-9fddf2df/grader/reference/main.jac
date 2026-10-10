"""Session query: live-preferred indexed search over session transcripts.

Models the essential scenario from the chroxy issue #7309 — a linear
substring scan over conversation content is replaced with a typed-edge
walk over Session -> Turn relationships, with a live-preferred read so
a turn just appended is findable without waiting for an index rebuild.
"""

node Session {
    has title: str = "";
    has project: str = "";
    has provider: str = "";
    has started_at: int = 0;
}

node Turn {
    has role: str = "";
    has content: str = "";
    has at: int = 0;
}

edge OwnedBy: any --> any { }
edge ForkOf: any --> any { }
edge NextTurn: any --> any { }

walker Indexer {
    has indexed: list[any] = [];

    can start with Root entry {
        visit [->:OwnedBy:->];
    }

    can index_session with Session entry {
        self.indexed.append(("SESSION", here.title));
        visit [->:ForkOf:->];
        visit [->:NextTurn:->];
    }

    can index_turn with Turn entry {
        self.indexed.append(("TURN", here.role, here.content));
        visit [->:NextTurn:->];
    }
}

walker Query {
    has needle: str = "";
    has role_filter: str = "";
    has hits: list[any] = [];

    can start with Root entry {
        visit [->:OwnedBy:->];
    }

    can scan_session with Session entry {
        visit [->:NextTurn:->];
    }

    can scan_turn with Turn entry {
        live_match = here.content.lower().find(self.needle.lower()) >= 0
            if here.content and self.needle else False;
        role_ok = (self.role_filter == "") or (here.role == self.role_filter);
        if live_match and role_ok {
            self.hits.append((here.role, here.content));
        }
        visit [->:NextTurn:->];
    }
}

walker LiveAppend {
    can append with Session entry {
        new_turn = Turn(role="user", content="just appended", at=9999);
        here +>:NextTurn:+> new_turn;
        print(f"appended live turn to {here.title}");
    }
}

with entry {
    main = Session(title="main", project="alpha", provider="openai", started_at=1);
    forked = Session(title="fork-A", project="alpha", provider="openai", started_at=2);
    root +>:OwnedBy:+> main;
    root +>:OwnedBy:+> forked;
    main +>:ForkOf:+> forked;

    t1 = Turn(role="user", content="search the corpus fast", at=10);
    t2 = Turn(role="assistant", content="use FTS5", at=11);
    t3 = Turn(role="user", content="needle in haystack", at=12);
    t4 = Turn(role="assistant", content="found the needle", at=13);
    main +>:NextTurn:+> t1 +>:NextTurn:+> t2 +>:NextTurn:+> t3 +>:NextTurn:+> t4;

    f1 = Turn(role="user", content="forked thread starts here", at=20);
    f2 = Turn(role="assistant", content="forked reply with needle", at=21);
    forked +>:NextTurn:+> f1 +>:NextTurn:+> f2;

    idx = Indexer();
    root spawn idx;
    print(f"indexed entries: {len(idx.indexed)}");

    q = Query(needle="needle", role_filter="");
    root spawn q;
    print(f"query hits before append: {q.hits}");

    main spawn LiveAppend();

    q2 = Query(needle="needle", role_filter="");
    root spawn q2;
    print(f"query hits after live append: {q2.hits}");
}
