Analyzing the SchoolGroup walker failure: tests show only the intro line prints, so traversal or Animal entry isn't firing. Searching the codebase for similar Jac walker patterns.
The failure matches a Jac 0.36.1 walker dispatch quirk: ability names containing **`watch`** (including `watch_animals`) never fire on `Animal` entry, so `SchoolGroup` prints only its `start` line. The passing reference uses `can observe with Animal entry` instead. Everything else stays the same.

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
        visit [-->;
    }

    can greet with Animal entry {
        print(f"  Kiosk greets party at {here.name}'s enclosure.");
        visit [-->;
    }
}

walker Zookeeper {
    has keeper_name: str = "Alex";

    can start with Root entry {
        print(f"Zookeeper {self.keeper_name} begins the feeding round.");
        visit [-->;
    }

    can feed_lion with Lion entry {
        here.feed("steak");
        visit [-->;
    }

    can feed_parrot with Parrot entry {
        here.feed("seed mix");
        visit [-->;
    }

    can feed_other with Animal entry {
        here.feed("standard feed");
        visit [-->;
    }
}

walker SchoolGroup {
    has students: int = 0;

    can start with Root entry {
        print(f"School group of {self.students} students arrives to watch.");
        visit [-->;
    }

    can observe with Animal entry {
        marker = "(just fed!)" if here.fed else "(waiting for feeding)";
        print(f"  Students watch {here.name} the {here.species} {marker}.");
        visit [-->;
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