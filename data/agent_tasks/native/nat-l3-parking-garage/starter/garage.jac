"""Multi-storey car park: Level nodes on root, Level -ParkedOn-> Car."""

node Level {
    has number: int;
    has spots: int;
}

node Car {
    has plate: str;
    has entered_at: int;
}

edge ParkedOn: Level --> Car {}

obj Ticket {
    has ok: bool;
    has level: int = -1;
    has reason: str = "";
}

walker AddLevel {
    has number: int;
    has spots: int;

    can add with Root entry {
        root ++> Level(number=self.number, spots=self.spots);
        report self.number;
    }
}
