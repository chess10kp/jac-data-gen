"""Simulate an outbreak sweeping a contact network level by level.

Health authorities want the wave structure: who is infected on day 1,
day 2, day 3. Appending newly exposed people to the END of the visit
queue (index -1) makes the walker finish each entire generation before
starting the next, which is breadth-first order.
"""

node Person {
    has name: str;
    has wave: int;   # distance from patient zero, fixed at build time
}

edge Contact {}

walker Outbreak {
    can start with Root entry {
        visit [-->];
    }

    can infect with Person entry {
        print(f"contacting {here.name} (wave {here.wave})");

        # Append at END of queue: everyone exposed now is served only
        # after everyone already waiting -- explicit BFS
        visit : -1 : [->:Contact:->];
    }
}

with entry {
    patient0 = Person(name="Patient 0", wave=0);
    friend1 = Person(name="Friend One", wave=1);
    friend2 = Person(name="Friend Two", wave=1);
    coworker = Person(name="Coworker", wave=2);
    roommate = Person(name="Roommate", wave=2);
    stranger = Person(name="Stranger", wave=3);

    root ++> patient0;
    patient0 +>: Contact() :+> friend1;
    patient0 +>: Contact() :+> friend2;
    friend1 +>: Contact() :+> coworker;
    friend2 +>: Contact() :+> roommate;
    coworker +>: Contact() :+> stranger;

    root spawn Outbreak();
}
