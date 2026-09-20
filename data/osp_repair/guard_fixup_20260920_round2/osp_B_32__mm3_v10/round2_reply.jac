The failure matches the known Jac 0.36.1 runtime bug: walker-attached `Animal` entry abilities stop firing after prior tests. Moving those abilities onto the `Animal` node (and species overrides onto `Lion`/`Parrot`) fixes type resolution and restores visitation.

```jac candidate
"""Wildlife park feeding rounds: kiosk greets all, zookeepers feed species-appropriate meals, school groups observe."""

node Animal {
    has species: str = "";
    has name: str = "";
    has fed: bool = False;

    def feed(meal: str) {
        self.fed = True;
        print(f"  {self.name} the {self.species} eats {meal}.");
    }

    can greet with InfoKiosk entry {
        print(f"  Kiosk greets party at {here.name}'s enclosure.");
        visit [-->];
    }

    can feed with Zookeeper entry {
        here.feed("standard feed");
        visit [-->];
    }

    can observe with SchoolGroup entry {
        marker = "(just fed!)" if here.fed else "(waiting for feeding)";
        print(f"  Students watch {here.name} the {here.species} {marker}.");
        visit [-->];
    }
}

node Lion(Animal) {
    override def feed(meal: str) {
        self.fed = True;
        print(f"  {self.name} the lion tears into a fresh {meal}.");
    }

    can feed with Zookeeper entry {
        here.feed("steak");
        visit [-->];
    }
}

node Parrot(Animal) {
    override def feed(meal: str) {
        self.fed = True;
        print(f"  {self.name} the parrot cracks {meal}.");
    }

    can feed with Zookeeper entry {
        here.feed("seed mix");
        visit [-->];
    }
}

walker InfoKiosk {
    can start with Root entry {
        print("Info kiosk: welcome to the wildlife park!");
        visit [-->];
    }
}

walker Zookeeper {
    has keeper_name: str = "Alex";

    can start with Root entry {
        print(f"Zookeeper {self.keeper_name} begins the feeding round.");
        visit [-->];
    }
}

walker SchoolGroup {
    has students: int = 0;

    can start with Root entry {
        print(f"School group of {self.students} students arrives to watch.");
        visit [-->];
    }
}

with entry {
    simba = Lion(species="lion", name="Simba");
    polly = Parrot(species="parrot", name="Polly");
    gopher = Animal(species="tortoise", name="Gopher");
    root ++> simba ++> polly ++> gopher;

    root spawn InfoKiosk();
    print("---");
    root spawn Zookeeper(keeper_name="Alex");
    print("---");
    root spawn SchoolGroup(students=24);
}
```

```jac tests
unchanged
```

**What changed**

1. **Node-attached entry abilities** — `greet` (InfoKiosk), `feed` (Zookeeper), and `observe` (SchoolGroup) live on `Animal`, with `Lion` and `Parrot` overriding `feed` for species-specific meals. Print strings are unchanged.
2. **Removed dead walker abilities** — walkers only keep their `start with Root entry` handlers.
3. **Dropped `-> None`** on `feed` — clears W3037; behavior is unchanged.
4. **Type resolution** — `here.fed`, `here.name`, and `here.species` are resolved on the node archetype, fixing W1051 in the old walker ability.

`Lion`/`Parrot` `can feed with Zookeeper entry` overrides the base `Animal` handler so dispatch stays lion → steak, parrot → seed mix, other → standard feed.