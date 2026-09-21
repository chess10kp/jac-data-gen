"""Revoke a grant to close a shared node back down.

`revoke(node)` strips the per-instance grant, returning the node to
its default closed state for everyone but the owner.
"""

node Note {
    has title: str;
    has body: str = "";
    has is_shared: bool = False;
}

walker create_note {
    has title: str;
    has body: str;

    can run with Root entry {
        report {"id": jid(here ++> Note(title=self.title, body=self.body))};
    }
}

walker set_share {
    has note_id: str;
    has open: bool;

    can find with Root entry {
        visit [-->];
    }

    can toggle with Note entry {
        if jid(here) == self.note_id {
            if self.open {
                grant(here, level=AccessLevel.READ);
                here.is_shared = True;
                report {"granted READ": here.title};
            } else {
                revoke(here);  # back to owner-only
                here.is_shared = False;
                report {"revoked": here.title};
            }
            disengage;
        }
    }
}

with entry {
    r = root spawn create_note(title="sprint retro notes", body="keep the graph tidy");
    nid = r.reports[0]["id"];

    root spawn set_share(note_id=nid, open=True);   # public for a while
    root spawn set_share(note_id=nid, open=False);  # ...then closed again

    final = root spawn set_share(note_id=nid, open=True);
    print(final.reports);
}
