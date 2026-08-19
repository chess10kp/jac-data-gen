"""AI Day Planner main -- adds a Notes feature alongside the app entry."""

to cl:

import from frontend { app as ClientApp }

def:pub app -> JsxElement {
    return
        <ClientApp/>;
}

to sv:

# Back to server-side: nodes, AI delegations, endpoints live here.

# New feature: a simple per-user Notes store with two endpoints.
node Note {
    has body: str,
        pinned: bool = False;
}

"""Create a note for the current user."""
def:priv add_note(body: str, pinned: bool = False) -> Note {
    note = root ++> Note(body=body, pinned=pinned);
    return note[0];
}

"""List the current user's notes, pinned ones first."""
def:priv get_notes -> list[Note] {
    notes = [root-->][?:Note];
    return [n for n in notes if n.pinned] + [n for n in notes if not n.pinned];
}
