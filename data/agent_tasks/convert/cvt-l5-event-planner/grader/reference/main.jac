"""Event planner API (port of AlanValdevenito/Planner-Web-Application).

Beanie `User` / `Event` documents -> `User` / `Event` nodes on root.
FastAPI routes -> public walkers named after the route handlers. JWT auth is
dropped: the acting user's email is passed explicitly as `user`.
"""
import hashlib;

glob NOT_FOUND: str = "Event with supplied ID does not exist";

node User {
    has email: str;
    has password: str;
}

node Event {
    has title: str;
    has image: str;
    has description: str;
    has location: str;
    has tags: list[str] = [];
    has creator: str = "";

    def view -> dict[str, any] {
        return {"id": jid(self), "title": self.title, "image": self.image,
                "description": self.description, "tags": list(self.tags),
                "location": self.location, "creator": self.creator};
    }
}

def find_event(event_id: str) -> Event | None {
    for e in [root -->[?:Event]] {
        if jid(e) == event_id {
            return e;
        }
    }
    return None;
}

"""POST /user/signup"""
walker:pub sign_new_user {
    has email: str;
    has password: str;

    can signup with Root entry {
        if any(u.email == self.email for u in [here -->[?:User]]) {
            report {"error": "User with supplied email already exists"};
            return;
        }
        hashed = hashlib.sha256(self.password.encode()).hexdigest();
        here ++> User(email=self.email, password=hashed);
        report {"message": "User created successfully"};
    }
}

"""GET /event/"""
walker:pub get_all_events {
    can list_all with Root entry {
        report [e.view() for e in [here -->[?:Event]]];
    }
}

"""GET /event/{event_id}"""
walker:pub get_event_by_id {
    has event_id: str;

    can fetch with Root entry {
        e = find_event(self.event_id);
        report e.view() if e else {"error": NOT_FOUND};
    }
}

"""POST /event/new -- the creator is the acting user."""
walker:pub create_event {
    has user: str;
    has title: str;
    has image: str;
    has description: str;
    has location: str;
    has tags: list[str] = [];

    can create with Root entry {
        e = here ++> Event(title=self.title, image=self.image, description=self.description,
                           tags=self.tags, location=self.location, creator=self.user);
        report {"message": "Event created successfully", "id": jid(e)};
    }
}

"""PUT /event/edit/{event_id} -- partial update, only the creator may edit."""
walker:pub update_event {
    has event_id: str;
    has user: str;
    has title: str | None = None;
    has image: str | None = None;
    has description: str | None = None;
    has tags: list[str] | None = None;
    has location: str | None = None;

    can edit with Root entry {
        e = find_event(self.event_id);
        if e is None {
            report {"error": NOT_FOUND};
            return;
        }
        if e.creator != self.user {
            report {"error": "Operation not allowed"};
            return;
        }
        if self.title is not None { e.title = self.title; }
        if self.image is not None { e.image = self.image; }
        if self.description is not None { e.description = self.description; }
        if self.tags is not None { e.tags = self.tags; }
        if self.location is not None { e.location = self.location; }
        report e.view();
    }
}

"""DELETE /event/{event_id} -- only the creator may delete."""
walker:pub delete_event {
    has event_id: str;
    has user: str;

    can remove with Root entry {
        e = find_event(self.event_id);
        if e is None {
            report {"error": NOT_FOUND};
            return;
        }
        if e.creator != self.user {
            report {"error": "Operation not allowed"};
            return;
        }
        del e;
        report {"message": "Event deleted successfully"};
    }
}

"""DELETE /event/ -- removes every event (any signed-in user may call it)."""
walker:pub delete_all_events {
    has user: str;

    can remove_all with Root entry {
        for e in [here -->[?:Event]] {
            del e;
        }
        report {"message": "All events deleted successfully"};
    }
}
