"""Supper club RSVPs: guests answer yes / no / maybe per event, yes answers may bring plus-ones, events may cap seats."""

node RsvpBook {
    has events: dict[str, dict[str, any]] = {};
    has names: dict[str, str] = {};
}

def _book -> RsvpBook {
    for n in [root -->] {
        if isinstance(n, RsvpBook) {
            return n;
        }
    }
    b = RsvpBook();
    root ++> b;
    return b;
}

def _event(b: RsvpBook, name: str) -> dict[str, any] {
    if name not in b.events {
        b.events[name] = {"capacity": 0, "answers": {}};
    }
    return b.events[name];
}

def _seats(ev: dict[str, any], ignore: str) -> int {
    total = 0;
    for key in ev["answers"] {
        a = ev["answers"][key];
        if key != ignore and a["answer"] == "yes" {
            total += 1 + a["plus"];
        }
    }
    return total;
}

"""Answer (or change the answer) for one event. Returns "ok" or an error string."""
def rsvp(event: str, guest: str, answer: str, plus_ones: int = 0) -> str {
    name = guest.strip();
    if not name {
        return "guest required";
    }
    if answer != "yes" and answer != "no" and answer != "maybe" {
        return "bad answer";
    }
    if plus_ones < 0 or plus_ones > 3 {
        return "plus_ones out of range";
    }
    b = _book();
    ev = _event(b, event);
    key = name.lower();
    if answer == "yes" and ev["capacity"] > 0 and _seats(ev, key) + 1 + plus_ones > ev["capacity"] {
        return "full";
    }
    b.names[key] = name;
    ev["answers"][key] = {"answer": answer, "plus": plus_ones};
    return "ok";
}

"""Cap the seats of an event (0 = no cap). Fails if more seats are already taken."""
def set_capacity(event: str, seats: int) -> bool {
    b = _book();
    ev = _event(b, event);
    if seats > 0 and _seats(ev, "") > seats {
        return False;
    }
    ev["capacity"] = seats;
    return True;
}

"""Seats taken: every yes plus their plus-ones."""
def headcount(event: str) -> int {
    b = _book();
    if event not in b.events {
        return 0;
    }
    return _seats(b.events[event], "");
}

"""Display names that gave this answer, sorted case-insensitively."""
def guests(event: str, answer: str) -> list[str] {
    b = _book();
    if event not in b.events {
        return [];
    }
    out: list[str] = [];
    answers = b.events[event]["answers"];
    for key in answers {
        if answers[key]["answer"] == answer {
            out.append(b.names[key]);
        }
    }
    return sorted(out, key=str.lower);
}

"""Events a guest is (maybe) coming to, as "event (yes)" / "event (maybe)", sorted."""
def agenda(guest: str) -> list[str] {
    b = _book();
    key = guest.strip().lower();
    out: list[str] = [];
    for name in b.events {
        answers = b.events[name]["answers"];
        if key in answers and answers[key]["answer"] != "no" {
            out.append(f"{name} ({answers[key]['answer']})");
        }
    }
    return sorted(out);
}

def cancel(event: str, guest: str) -> bool {
    b = _book();
    key = guest.strip().lower();
    if event not in b.events or key not in b.events[event]["answers"] {
        return False;
    }
    b.events[event]["answers"].pop(key);
    return True;
}
