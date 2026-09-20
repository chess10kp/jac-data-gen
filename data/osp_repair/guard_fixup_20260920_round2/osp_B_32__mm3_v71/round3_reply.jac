The failure matches the known Jac 0.36.1 bug: walker-attached `Animal` entry abilities stop firing after other walkers have already visited those nodes. Moving all three `Animal` entry handlers onto the `Animal` node archetype fixes runtime behavior and resolves the `here` type warnings.

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