Analyzing the failure and Jac patterns to produce a repaired candidate; checking the workspace for similar fixes.
The failure matches the Jac 0.36.1 runtime bug (walker-attached `Animal` entry abilities stop firing after earlier tests) plus type-resolution errors on node-attached abilities: in `can … with Walker entry` on a node, `here` is the walker — use `self` for the animal.

```jac candidate
"""Wildlife park feeding rounds: kiosk greets all, zookeepers feed species-appropriate meals, school groups observe."""

node Animal {
    has species: str = "";
    has name: str = "";
    has fed: bool = False;

    def feed(meal: str) -> None {
        self.fed = True;
        print(f"  {self.name} the {self.species} eats {meal}.");
    }

    can greet with InfoKiosk entry {
        print(f"  Kiosk greets party at {self.name}'s enclosure.");
        visit [-->];
    }

    can feed with Zookeeper entry {
        self.feed("standard feed");
        visit [-->];
    }

    can observe with SchoolGroup entry {
        marker = "(just fed!)" if self.fed else "(waiting for feeding)";
        print(f"  Students watch {self.name} the {self.species} {marker}.");
        visit [-->];
    }
}

node Lion(Animal) {
    override def feed(meal: str) -> None {
        self.fed = True;
        print(f"  {self.name} the lion tears into a fresh {meal}.");
    }

    can feed with Zookeeper entry {
        self.feed("steak");
        visit [-->];
    }
}

node Parrot(Animal) {
    override def feed(meal: str) -> None {
        self.fed = True;
        print(f"  {self.name} the parrot cracks {meal}.");
    }

    can feed with Zookeeper entry {
        self.feed("seed mix");
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

1. **Moved entry abilities onto nodes** — `greet` (InfoKiosk), `feed` (Zookeeper), and `observe` (SchoolGroup) now live on `Animal`, with `Lion` and `Parrot` overriding `feed` for species-specific meals. This avoids the runtime bug where walker-attached `with Animal entry` abilities stop firing after prior tests traverse animals.

2. **Fixed bindings** — In node-attached `can … with Walker entry` abilities, `here` is the entering walker; animal fields and methods use `self` instead. That clears the W1051 errors on `here.feed`, `here.name`, and `here.fed`.

3. **Walkers keep only `start`** — InfoKiosk, Zookeeper, and SchoolGroup retain just their `start with Root entry` handlers; the removed walker-side copies are dead code.

Print strings are byte-identical to what the tests assert. `Lion`/`Parrot` `can feed with Zookeeper entry` overrides the base `Animal` handler so dispatch stays lion → steak, parrot → seed mix, other → standard feed.