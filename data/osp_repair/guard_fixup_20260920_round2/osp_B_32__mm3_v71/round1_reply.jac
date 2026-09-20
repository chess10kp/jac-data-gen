The failures match the known Jac 0.36.1 runtime bug: walker-attached `Animal` entry abilities stop firing after earlier tests walk `Animal` nodes. Moving `feed` and `watch` onto `node Animal` (triggered by `Zookeeper` / `SchoolGroup` entry) fixes that while keeping print text byte-identical.

```jac candidate
"""Wildlife park feeding rounds.

The info kiosk greets every tour party regardless of type (union trigger).
Zookeepers feed each animal its species-appropriate meal. School groups
just observe.
"""

node Animal {
    has name: str = "";
    has species: str = "";

    def meal() -> str {
        return "standard feed";
    }

    can feed with Zookeeper entry {
        meal = here.meal();
        print(f"Feeding {here.name} the {here.species}: {meal}");
        visit [-->];
    }

    can watch with SchoolGroup entry {
        print(f"Students observe {here.name} the {here.species}");
        visit [-->];
    }
}

node Lion(Animal) {
    has name: str = "";
    has species: str = "lion";

    override def meal() -> str {
        return "meat";
    }
}

node Parrot(Animal) {
    has name: str = "";
    has species: str = "parrot";

    override def meal() -> str {
        return "seed";
    }
}

walker Tourist {
    has party_name: str = "";

    can start with Root entry {
        print(f"Welcome, {self.party_name} party!");
        visit [-->];
    }

    can greet with Animal entry {
        print(f"Kiosk: enjoy viewing {here.name} the {here.species}");
        visit [-->];
    }
}

walker Zookeeper {
    can start with Root entry {
        print("Zookeeper starting feeding rounds");
        visit [-->];
    }
}

walker SchoolGroup {
    has school: str = "";

    can start with Root entry {
        print(f"School group from {self.school} arriving");
        visit [-->];
    }
}

with entry {
    simba = Lion(name="Simba");
    polly = Parrot(name="Polly");
    thumper = Animal(name="Thumper", species="rabbit");

    root ++> simba ++> polly ++> thumper;

    Tourist(party_name="Smith family") spawn root;
    print("---");
    Zookeeper() spawn root;
    print("---");
    SchoolGroup(school="Westwood Elementary") spawn root;
}
```

```jac tests
unchanged
```

**What changed:** `can feed with Zookeeper entry` and `can watch with SchoolGroup entry` were moved from their walkers onto `node Animal`. `Lion` and `Parrot` inherit those handlers, so feeding and observation still run for every animal. `Tourist`’s `can greet with Animal entry` stays on the walker because that test already passes and the hint targets only the broken `feed` / `watch` pair.