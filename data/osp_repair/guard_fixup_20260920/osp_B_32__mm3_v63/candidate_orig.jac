"""Wildlife park feeding rounds.

The info kiosk greets every tour party regardless of kind (union
trigger). Zookeepers feed each animal its species-appropriate meal via
a per-species override on ``feed()``. School groups just watch the
animals — they don't feed.
"""

node Animal {
    has name: str = "";
    has species: str = "";

    def feed() -> str {
        return "standard feed";
    }
}

node Lion(Animal) {
    override def feed() -> str {
        return "meat";
    }
}

node Parrot(Animal) {
    override def feed() -> str {
        return "seed";
    }
}

node Kiosk {
    has kiosk_name: str = "Main";

    can greet with Zookeeper | SchoolGroup entry {
        print(f"Welcome to the {self.kiosk_name} kiosk, tour party!");
    }
}

walker Zookeeper {
    has badge: str = "Z-001";
    can start with Root entry {
        visit [-->];
    }
    can walk with Kiosk entry {
        visit [-->];
    }
    can feed_animals with Animal entry {
        meal = here.feed();
        print(f"{self.badge} feeds {here.name} the {here.species}: {meal}");
        visit [-->];
    }
}

walker SchoolGroup {
    has grade: int = 0;
    can start with Root entry {
        visit [-->];
    }
    can walk with Kiosk entry {
        visit [-->];
    }
    can watch with Animal entry {
        print(f"Grade {self.grade} watches {here.name} the {here.species}");
        visit [-->];
    }
}

with entry {
    kiosk_node = Kiosk(kiosk_name="Safari");
    lion_node = Lion(name="Simba", species="lion");
    parrot_node = Parrot(name="Polly", species="parrot");
    generic_node = Animal(name="Gobi", species="antelope");

    root ++> kiosk_node ++> lion_node ++> parrot_node ++> generic_node;

    zk = Zookeeper(badge="Z-042");
    root spawn zk;

    sg = SchoolGroup(grade=4);
    root spawn sg;
}