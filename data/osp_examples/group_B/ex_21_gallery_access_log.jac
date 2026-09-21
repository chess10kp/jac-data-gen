"""Gallery access logging.

The security system in each gallery room reacts to every walker that
steps in (generic ``with entry``), while a separate typed ability
(``with Curator entry``) grants curators an inspection that tourists
never trigger.
"""

node GalleryRoom {
    has exhibit: str;

    # Generic entry: fires for ANY walker that enters this node.
    can log_entry with entry {
        print(f"[security log] someone entered the {self.exhibit} room");
    }

    # Typed entry: fires only when the visiting walker is a Curator.
    can curate with Curator entry {
        print(f"[curator] {visitor.name} is inspecting '{self.exhibit}'");
        visitor.rooms_inspected += 1;
    }
}

walker Tourist {
    has name: str;

    can start with Root entry {
        visit [-->];
    }

    can wander with GalleryRoom entry {
        visit [-->];
    }
}

walker Curator {
    has name: str;
    has rooms_inspected: int = 0;

    can start with Root entry {
        visit [-->];
    }

    can inspect with GalleryRoom entry {
        visit [-->];
    }
}

with entry {
    modern = GalleryRoom(exhibit="Modern Painting");
    classical = GalleryRoom(exhibit="Classical Sculpture");
    root ++> modern ++> classical;

    print("--- tourist tour ---");
    root spawn Tourist(name="Mia");

    print("--- curator inspection ---");
    dr_reyes = Curator(name="Dr. Reyes");
    root spawn dr_reyes;
    print(f"Dr. Reyes inspected {dr_reyes.rooms_inspected} rooms");
}
