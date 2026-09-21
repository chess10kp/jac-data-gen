"""Veterinary clinic day: a walker that carries state across visits.

The vet starts the round with an empty patient list and a count of
vaccines given. Every pet visited appends to the walker's own state,
and the final summary reads straight off the walker instance.
"""

node Pet {
    has name: str = "";
    has species: str = "";
    has needs_shot: bool = False;
}

walker VetRound {
    has patients: list[str] = [];
    has shots_given: int = 0;

    can start with Root entry {
        print("Vet round starting");
        visit [-->];
    }

    can examine with Pet entry {
        self.patients.append(here.name);
        if here.needs_shot {
            self.shots_given += 1;
            print(f"{here.name} the {here.species}: vaccine given");
        } else {
            print(f"{here.name} the {here.species}: routine checkup, no shot needed");
        }
        visit [-->];
    }
}

with entry {
    root ++> Pet(name="Rex", species="dog", needs_shot=True)
        ++> Pet(name="Whiskers", species="cat")
        ++> Pet(name="Biscuit", species="hamster")
        ++> Pet(name="Bella", species="dog", needs_shot=True);

    vet = root spawn VetRound();
    print(f"Seen today ({len(vet.patients)}): {', '.join(vet.patients)}");
    print(f"Vaccines administered: {vet.shots_given}");
}
