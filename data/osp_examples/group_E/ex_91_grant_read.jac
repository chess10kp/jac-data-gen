"""Share a private note with everyone by granting READ.

`grant(note, level=AccessLevel.READ)` arms a per-instance grant: other
users get exactly READ while the rest of the graph stays sealed.
"""

node Note {
    has title: str;
    has body: str = "";
}

def show_levels() -> None {
    # Ambient enum: no import needed; qualify members via AccessLevel.
    print("levels:", str(AccessLevel.NO_ACCESS), str(AccessLevel.READ),
          str(AccessLevel.CONNECT), str(AccessLevel.WRITE));
}

walker create_note {
    has title: str;
    has body: str;

    can run with Root entry {
        n = here ++> Note(title=self.title, body=self.body);
        report {"id": jid(n), "title": n.title};
    }
}

walker share_note {
    has note_id: str;

    can run with Root entry {
        visit [-->];
    }

    can arm with Note entry {
        if jid(here) == self.note_id {
            # Per-instance policy the OWNER decides at runtime.
            grant(here, level=AccessLevel.READ);
            report {"shared": here.title};
            disengage;
        }
    }
}

walker read_note {
    has note_id: str;

    can run with Root entry {
        visit [-->];
    }

    can peek with Note entry {
        if jid(here) == self.note_id {
            report {"reading": here.title, "body": here.body};
        }
    }
}

with entry {
    show_levels();

    r = root spawn create_note(title="conference takeaways", body="walkers > services");
    nid = r.reports[0]["id"];
    root spawn create_note(title="private grocery list", body="do not share");

    root spawn share_note(note_id=nid);

    reader = root spawn read_note(note_id=nid);
    print(reader.reports);
}
