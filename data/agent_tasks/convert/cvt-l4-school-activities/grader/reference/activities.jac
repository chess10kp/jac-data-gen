"""Extracurricular activities (Mergington High School) as a graph.

Beanie `Club` / `Event` / `Registration` documents become nodes; the string
foreign keys (`club_id`, `event_id`) become edges Club -[Hosts]-> Event
-[HasRegistration]-> Registration. Route handlers become walkers; HTTP errors
are reported as {"status": <code>, "detail": <message>}.
"""

import datetime;

node Club {
    has name: str;
    has description: str;
    has coordinator_id: str;
    has status: str = "pending";
}

node Event {
    has name: str;
    has description: str;
    has schedule: str;
    has max_participants: int;
    has coordinator_id: str = "";
    has status: str = "pending";
}

node Registration {
    has student_id: str;
    has status: str = "active";
    has registered_at: str = "";
    has cancelled_at: str | None = None;
}

edge Hosts: Club --> Event {}
edge HasRegistration: Event --> Registration {}

def utcnow -> str {
    return datetime.datetime.utcnow().isoformat();
}

def err(code: int, detail: str) -> dict[str, any] {
    return {"status": code, "detail": detail};
}

def find_club(name: str) -> Club | None {
    for c in [root -->[?:Club]] {
        if c.name == name {
            return c;
        }
    }
    return None;
}

def find_event(name: str) -> Event | None {
    for c in [root -->[?:Club]] {
        for e in [c ->:Hosts:->] {
            if e.name == name {
                return e;
            }
        }
    }
    return None;
}

def active_registrations(e: Event) -> list[Registration] {
    return [r for r in [e ->:HasRegistration:->] if r.status == "active"];
}

walker create_club {
    has name: str;
    has description: str;
    has coordinator_id: str;

    can create with Root entry {
        if find_club(self.name) {
            report err(400, "Club name already exists");
            return;
        }
        c = here ++> Club(name=self.name, description=self.description, coordinator_id=self.coordinator_id);
        report {"id": jid(c), "name": c.name, "status": c.status};
    }
}

walker create_event {
    has club_name: str;
    has name: str;
    has description: str;
    has schedule: str;
    has max_participants: int;

    can create with Root entry {
        club = find_club(self.club_name);
        if club is None {
            report err(404, "Club not found");
            return;
        }
        e = Event(name=self.name, description=self.description, schedule=self.schedule,
                  max_participants=self.max_participants, coordinator_id=club.coordinator_id);
        club +>:Hosts:+> e;
        report {"id": jid(e), "name": e.name, "status": e.status};
    }
}

walker approve_event {
    has name: str;

    can approve with Root entry {
        e = find_event(self.name);
        if e is None {
            report err(404, "Activity not found");
            return;
        }
        e.status = "approved";
        report {"id": jid(e), "name": e.name, "status": e.status};
    }
}

"""GET /activities: approved events keyed by name, with live participant counts."""
walker get_activities {
    can list_all with Root entry {
        activities: dict[str, dict[str, any]] = {};
        for c in [-->[?:Club]] {
            for e in [c ->:Hosts:->] {
                if e.status == "approved" {
                    activities[e.name] = {"description": e.description, "schedule": e.schedule,
                                          "max_participants": e.max_participants,
                                          "participants": len(active_registrations(e)), "_id": jid(e)};
                }
            }
        }
        report activities;
    }
}

walker signup_for_activity {
    has activity_name: str;
    has email: str;

    can signup with Root entry {
        e = find_event(self.activity_name);
        if e is None {
            report err(404, "Activity not found");
            return;
        }
        active = active_registrations(e);
        if len(active) >= e.max_participants {
            report err(400, "Activity is at maximum capacity");
            return;
        }
        if any(r.student_id == self.email for r in active) {
            report err(400, "Student is already signed up");
            return;
        }
        e +>:HasRegistration:+> Registration(student_id=self.email, registered_at=utcnow());
        report {"message": f"Signed up {self.email} for {self.activity_name}"};
    }
}

walker unregister_from_activity {
    has activity_name: str;
    has email: str;

    can unregister with Root entry {
        e = find_event(self.activity_name);
        if e is None {
            report err(404, "Activity not found");
            return;
        }
        mine = [r for r in active_registrations(e) if r.student_id == self.email];
        if not mine {
            report err(400, "Student is not signed up for this activity");
            return;
        }
        mine[0].status = "cancelled";
        mine[0].cancelled_at = utcnow();
        report {"message": f"Unregistered {self.email} from {self.activity_name}"};
    }
}
