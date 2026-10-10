"""Implementations for rsvp.jac."""

impl Respond.record {
    ev = event_node(self.event);
    name = self.guest.strip();
    key = name.lower();
    if self.answer == Answer.YES and ev.capacity > 0 {
        taken = (ev spawn Roster(ignore=key)).seats;
        if taken + 1 + self.plus_ones > ev.capacity {
            self.result = "full";
            return;
        }
    }
    g = find_guest(name);
    if g is None {
        g = here ++> Guest(key=key, display=name);
    } else {
        g.display = name;
    }
    del [edge g ->:Rsvp:-> ev];
    g +>:Rsvp(answer=self.answer, plus_ones=self.plus_ones):+> ev;
    self.result = "ok";
}

impl Roster.count {
    for g in [here <-:Rsvp:<-] {
        for r in [edge g ->:Rsvp:-> here] {
            if r.answer == Answer.YES {
                self.yes.append(g.display);
                if g.key != self.ignore {
                    self.seats += 1 + r.plus_ones;
                }
            } elif r.answer == Answer.NO {
                self.no.append(g.display);
            } else {
                self.maybe.append(g.display);
            }
        }
    }
}

impl Agenda.collect {
    for ev in [here ->:Rsvp:->] {
        for r in [edge here ->:Rsvp:-> ev] {
            if r.answer != Answer.NO {
                self.lines.append(f"{ev.name} ({r.answer.value})");
            }
        }
    }
}

impl parse_answer(answer: str) -> Answer | None {
    match answer {
        case "yes":
            return Answer.YES;
        case "no":
            return Answer.NO;
        case "maybe":
            return Answer.MAYBE;
        case _:
            return None;
    }
}

impl find_event(name: str) -> Event | None {
    wanted = name;
    found = [root -->[?:Event, name == wanted]];
    return found[0] if found else None;
}

impl find_guest(name: str) -> Guest | None {
    wanted = name.strip().lower();
    found = [root -->[?:Guest, key == wanted]];
    return found[0] if found else None;
}

impl event_node(name: str) -> Event {
    ev = find_event(name);
    return ev if ev is not None else root ++> Event(name=name);
}

impl rsvp(event: str, guest: str, answer: str, plus_ones: int = 0) -> str {
    if not guest.strip() {
        return "guest required";
    }
    a = parse_answer(answer);
    if a is None {
        return "bad answer";
    }
    if plus_ones < 0 or plus_ones > 3 {
        return "plus_ones out of range";
    }
    w = root spawn Respond(event=event, guest=guest, answer=a, plus_ones=plus_ones);
    return w.result;
}

impl set_capacity(event: str, seats: int) -> bool {
    ev = event_node(event);
    if seats > 0 and (ev spawn Roster()).seats > seats {
        return False;
    }
    ev.capacity = seats;
    return True;
}

impl headcount(event: str) -> int {
    ev = find_event(event);
    return 0 if ev is None else (ev spawn Roster()).seats;
}

impl guests(event: str, answer: str) -> list[str] {
    ev = find_event(event);
    a = parse_answer(answer);
    if ev is None or a is None {
        return [];
    }
    r = ev spawn Roster();
    names = r.yes if a == Answer.YES else (r.no if a == Answer.NO else r.maybe);
    return sorted(names, key=str.lower);
}

impl agenda(guest: str) -> list[str] {
    g = find_guest(guest);
    if g is None {
        return [];
    }
    return sorted((g spawn Agenda()).lines);
}

impl cancel(event: str, guest: str) -> bool {
    ev = find_event(event);
    g = find_guest(guest);
    if ev is None or g is None or not [edge g ->:Rsvp:-> ev] {
        return False;
    }
    del [edge g ->:Rsvp:-> ev];
    return True;
}
