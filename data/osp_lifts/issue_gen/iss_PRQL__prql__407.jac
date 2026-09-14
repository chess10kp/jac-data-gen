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
