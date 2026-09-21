"""Wildlife park feeding rounds.

Animal taxonomy forms an inheritance hierarchy (Animal -> Mammal |
Bird -> concrete species). Two very different walkers tour the park,
and the info kiosk greets both with one anonymous ability that fires
for every visitor.
"""

node Animal {
    has name: str;

    def meal() -> str {
        return "standard feed";
    }
}

node Mammal(Animal) {
    override def meal() -> str {
        return "hay and fruit";
    }
}

node Bird(Animal) {
    override def meal() -> str {
        return "seed mix";
    }
}

node Lion(Mammal) {
    override def meal() -> str {
        return "10 kg of meat";
    }
}

node Parrot(Bird) {}

node InfoKiosk {
    # No type filter: runs for Zookeeper AND SchoolGroup alike.
    can greet with entry {
        print(f"kiosk display: welcome, {type(visitor).__name__}");
    }
}

walker Zookeeper {
    has fed: int = 0;

    can start with Root entry {
        visit [-->];
    }

    can pass_kiosk with InfoKiosk entry {
        visit [-->];
    }

    can feed with Animal entry {
        self.fed += 1;
        print(f"feeding {here.name}: {here.meal()}");
        visit [-->];
    }
}

walker SchoolGroup {
    has children: int;

    can start with Root entry {
        visit [-->];
    }

    can pass_kiosk with InfoKiosk entry {
        visit [-->];
    }

    can watch with Animal entry {
        print(f"{self.children} children watch {here.name}");
        visit [-->];
    }
}

with entry {
    kiosk = InfoKiosk();
    savanna = Animal(name="Savanna Run");
    root ++> kiosk ++> savanna;

    leo = Lion(name="Leo");
    coco = Parrot(name="Coco");
    savanna ++> leo;
    savanna ++> coco;

    keeper = Zookeeper();
    root spawn keeper;

    class5b = SchoolGroup(children=24);
    root spawn class5b;
}
