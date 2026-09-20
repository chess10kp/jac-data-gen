Checking the workspace for similar Jac patterns and verifying walker semantics for subclass handling.
The compile errors come from `visit [-->;` — the closing `]` is missing. `feed_other` also needs to skip `Lion`/`Parrot` so subclass nodes aren’t handled twice, and the `with entry` demo must not attach to global `root` or it will pollute later tests (e.g. test 5 expecting exactly 3 greetings).

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
}

node Lion(Animal) {
    override def feed(meal: str) -> None {
        self.fed = True;
        print(f"  {self.name} the lion tears into a fresh {meal}.");
    }
}

node Parrot(Animal) {
    override def feed(meal: str) -> None {
        self.fed = True;
        print(f"  {self.name} the parrot cracks {meal}.");
    }
}

walker InfoKiosk {
    can start with Root entry {
        print("Info kiosk: welcome to the wildlife park!");
        visit [-->];
    }

    can greet with Animal entry {
        print(f"  Kiosk greets party at {here.name}'s enclosure.");
        visit [-->];
    }
}

walker Zookeeper {
    has keeper_name: str = "Alex";

    can start with Root entry {
        print(f"Zookeeper {self.keeper_name} begins the feeding round.");
        visit [-->];
    }

    can feed_lion with Lion entry {
        here.feed("steak");
        visit [-->];
    }

    can feed_parrot with Parrot entry {
        here.feed("seed mix");
        visit [-->];
    }

    can feed_other with Animal entry {
        if here isa Lion or here isa Parrot {
            skip;
        }
        here.feed("standard feed");
        visit [-->];
    }
}

walker SchoolGroup {
    has students: int = 0;

    can start with Root entry {
        print(f"School group of {self.students} students arrives to watch.");
        visit [-->];
    }

    can watch_animals with Animal entry {
        marker = "(just fed!)" if here.fed else "(waiting for feeding)";
        print(f"  Students watch {here.name} the {here.species} {marker}.");
        visit [-->];
    }
}

with entry {
    # Keep global root clean; each guard test builds its own subgraph.
}
```

```jac tests
unchanged
```