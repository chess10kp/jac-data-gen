"""Guestbook API: visitors leave entries; each entry is an `Entry` node on root.

Port of okteto/guestbook-api (FastAPI + ODMantic/Mongo). Mongo collection ->
nodes attached to root; route handlers -> public walkers (POST /walker/<name>).
"""
import from datetime { datetime }

node Entry {
    has name: str;
    has `entry: str;
    has date: str = "";

    def view -> dict[str, str] {
        return {"id": jid(self), "name": self.name, "entry": self.entry, "date": self.date};
    }
}

"""GET / -- welcome banner."""
walker:pub welcome {
    can greet with Root entry {
        report {"message": "Welcome to the FastAPI + Okteto series in development mode!"};
    }
}

"""GET /entries -- every entry in insertion order."""
walker:pub retrieve_entries {
    can list_all with Root entry {
        report {"entries": [e.view() for e in [-->[?:Entry]]]};
    }
}

"""POST /entry -- store a new entry and report its id."""
walker:pub add_entry {
    has name: str;
    has `entry: str;

    can add with Root entry {
        e = here ++> Entry(name=self.name, `entry=self.entry, date=datetime.now().isoformat());
        report {"message": f"New entry added with ID: {jid(e)}"};
    }
}

"""DELETE /entry/{id} -- remove the entry if it exists; always succeeds."""
walker:pub delete_entry {
    has id: str;

    can remove with Root entry {
        for e in [-->[?:Entry]] {
            if jid(e) == self.id {
                del e;
            }
        }
        report {"message": "Entry deleted successfully"};
    }
}
