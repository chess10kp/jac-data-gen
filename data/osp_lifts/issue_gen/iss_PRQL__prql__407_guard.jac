node Event {
    has event_id: str;
    has delta: int = 0;
}

node Feed {
    has first: Event | None = None;
}

edge Next {}
edge HasEvent {}

walker FoldWalker {
    has claimed: dict[str, bool] = {};
    has requested: str = "";
    has states: list[int] = [];
    has total: int = 0;

    can choose_feed with Feed entry {
        if self.requested == "" {
            first_event = here.first;
            if first_event != None {
                visit :0: [first_event];
            }
        } else {
            for candidate in [here ->:HasEvent:->][?:Event] {
                if candidate.event_id == self.requested {
                    visit :0: [candidate];
                }
            }
        }
        print(self.total);
    }

    can fold_event with Event entry {
        if here.event_id in self.claimed {
            skip;
        }
        self.claimed[here.event_id] = True;
        self.total += here.delta;
        self.states.append(self.total);
        print(self.total);

        for child in [here ->:Next:->][?:Event] {
            visit :0: [child];
        }
    }
}

def make_feed(deltas: list[int]) -> Feed {
    feed = Feed();
    previous: Event | None = None;

    for i in range(len(deltas)) {
        current = Event(event_id="e" + str(i), delta=deltas[i]);
        feed +>:HasEvent:+> current;

        if i == 0 {
            feed.first = current;
        }

        prior = previous;
        if prior != None {
            prior +>:Next:+> current;
        }
        previous = current;
    }

    return feed;
}

def fold_events(deltas: list[int]) -> list[int] {
    feed = make_feed(deltas);
    w = feed spawn FoldWalker();
    return w.states;
}

def fold_all(feed: Feed) -> list[int] {
    w = feed spawn FoldWalker();
    return w.states;
}

def fold_from(feed: Feed, event_id: str) -> list[int] {
    w = feed spawn FoldWalker(requested=event_id);
    return w.states;
}

test "linear fold and public APIs" {
    feed = make_feed([1, 2, 3]);
    assert (fold_events([1, 2, 3]) == [1, 3, 6]);
    assert (fold_all(feed) == [1, 3, 6]);
    assert (fold_from(feed, "e1") == [2, 5]);
}

test "unknown event id is tolerated" {
    feed = make_feed([4, 5]);
    assert (fold_from(feed, "missing") == []);
}

test "diamond revisit keeps deeper closure" {
    feed = Feed();
    a = Event(event_id="a", delta=1);
    b = Event(event_id="b", delta=2);
    c = Event(event_id="c", delta=3);
    d = Event(event_id="d", delta=4);
    e = Event(event_id="e", delta=5);

    feed.first = a;
    feed +>:HasEvent:+> a;
    a +>:Next:+> b;
    a +>:Next:+> c;
    b +>:Next:+> d;
    c +>:Next:+> d;
    d +>:Next:+> e;

    states = fold_all(feed);
    assert (len(states) == 5);
    assert (states[len(states) - 1] == 15);
}

test "empty and negative folds" {
    assert (fold_events([]) == []);

    feed = make_feed([-2, 5, -1]);
    assert (fold_all(feed) == [-2, 3, 2]);
}
