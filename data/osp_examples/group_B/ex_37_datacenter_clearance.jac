"""Data center access control.

Server rooms carry a required clearance level like secure doors. The
technician walker inspects ``here.clearance_required`` on arrival and
calls ``disengage`` to end its whole walk when its own clearance falls
short, so a denied technician never reaches the deeper rooms behind
the checkpoint.
"""

node Corridor {
    has name: str;
}

node ServerRoom {
    has room: str;
    has clearance_required: int;
}

walker Technician {
    has tech_name: str;
    has clearance: int;
    has rooms_seen: int = 0;

    can start with Root entry {
        visit [-->];
    }

    can walk with Corridor entry {
        visit [-->];
    }

    can audit with ServerRoom entry {
        if self.clearance < here.clearance_required {
            print(f"DENIED  {self.tech_name}: {here.room} needs level "
                  f"{here.clearance_required}");
            disengage;
        }
        self.rooms_seen += 1;
        print(f"GRANTED {self.tech_name} enters {here.room}");
        visit [-->];
    }
}

with entry {
    main_hall = Corridor(name="Main Hall");
    cage_row = Corridor(name="Cage Row");
    vault_wing = Corridor(name="Vault Wing");
    root ++> main_hall ++> cage_row ++> vault_wing;

    r101 = ServerRoom(room="R-101 network core", clearance_required=1);
    r102 = ServerRoom(room="R-102 storage vault", clearance_required=3);
    r103 = ServerRoom(room="R-103 backup tapes", clearance_required=2);
    cage_row ++> r101 ++> r102 ++> r103;

    junior = Technician(tech_name="Kim", clearance=1);
    root spawn junior;
    print(f"Kim reached {junior.rooms_seen} room(s)");

    senior = Technician(tech_name="Alex", clearance=3);
    root spawn senior;
    print(f"Alex reached {senior.rooms_seen} room(s)");
}
