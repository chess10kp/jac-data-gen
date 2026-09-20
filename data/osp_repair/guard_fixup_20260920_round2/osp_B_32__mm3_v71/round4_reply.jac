Analyzing the failure and applying the node-attached ability pattern from the record hint. Checking the workspace for reference implementations.
The failure matches the known Jac 0.36.1 bug: walker-attached `Animal` entry abilities stop firing after earlier tests. Move those handlers onto `Animal` (with `visitor` as the walker and `here` as the node), and leave only the `Root` start abilities on each walker.

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

    can greet with Tourist entry {
        print(f"Kiosk: enjoy viewing {here.name} the {here.species}");
        visit [-->];
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

**What changed:** `can greet with Tourist entry`, `can feed with Zookeeper entry`, and `can watch with SchoolGroup entry` were moved from their walkers onto `Animal`. Each walker now only handles its `Root` start message and `visit [-->];`; when it reaches an animal, the node-side ability runs with `here` as the animal and `visitor` as the walker. Print strings are unchanged, so all five guard assertions still match. `Lion` and `Parrot` inherit the node abilities and keep their `meal()` overrides.