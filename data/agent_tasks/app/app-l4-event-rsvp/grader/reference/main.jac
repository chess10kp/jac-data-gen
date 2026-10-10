"""Event RSVPs: Event nodes, Guest nodes, and an Rsvp edge per guest per event."""

node Event {
    has name: str;
}

node Guest {
    has key: str;
    has display: str;
}

edge Rsvp: Guest --> Event {
    has attending: bool;
    has plus_ones: int = 0;
}

def summary(ev: Event) -> dict[str, any] {
    attending: list[str] = [];
    declined: list[str] = [];
    headcount = 0;
    for g in [ev <-:Rsvp:<-] {
        for r in [edge g ->:Rsvp:-> ev] {
            if r.attending {
                attending.append(g.display);
                headcount += 1 + r.plus_ones;
            } else {
                declined.append(g.display);
            }
        }
    }
    order = lambda (s: str) -> str { return s.lower(); };
    return {"event": ev.name, "headcount": headcount,
            "attending": sorted(attending, key=order), "declined": sorted(declined, key=order)};
}

walker:pub rsvp {
    has event: str;
    has guest: str;
    has attending: bool;
    has plus_ones: int = 0;

    can answer with Root entry {
        if self.plus_ones < 0 or self.plus_ones > 3 {
            report {"error": "plus_ones must be between 0 and 3"};
            return;
        }
        name = self.guest.strip();
        if not name {
            report {"error": "guest required"};
            return;
        }
        events = [e for e in [here -->[?:Event]] if e.name == self.event];
        ev = events[0] if events else here ++> Event(name=self.event);
        guests = [g for g in [here -->[?:Guest]] if g.key == name.lower()];
        if guests {
            g = guests[0];
            g.display = name;
        } else {
            g = here ++> Guest(key=name.lower(), display=name);
        }
        del [edge g ->:Rsvp:-> ev];
        g +>:Rsvp(attending=self.attending, plus_ones=self.plus_ones):+> ev;
        report summary(ev);
    }
}
