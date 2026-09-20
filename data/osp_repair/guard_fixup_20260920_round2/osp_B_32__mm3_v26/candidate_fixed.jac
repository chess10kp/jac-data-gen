"""Wildlife park feeding rounds.

The info kiosk greets every tour party unconditionally. Zookeepers feed
each animal its species-appropriate meal: meat for lions, seed for
parrots, and a standard feed otherwise. School groups just observe the
animals without taking any feeding action.
"""

node Animal {
    has species: str = "";
    has name: str = "";

    def meal -> str {
        return "standard feed";
    }

    can observe with Visitor entry {
        print(f"{visitor.party} watches {self.name} the {self.species}.");
        visit [-->];
    }

    can feed with Zookeeper entry {
        print(f"Zookeeper {visitor.keeper} feeds {self.name} the {self.species}: {self.meal()}.");
        visit [-->];
    }

    can watch with SchoolGroup entry {
        print(f"{visitor.class_name} quietly observes {self.name} the {self.species}.");
        visit [-->];
    }
}

node Lion(Animal) {
    override def meal -> str {
        return "meat";
    }
}

node Parrot(Animal) {
    override def meal -> str {
        return "seed";
    }
}

node InfoKiosk {
    has kiosk_name: str = "Welcome Hut";
}

walker Visitor {
    has party: str = "tourists";

    can start with Root entry {
        visit [-->];
    }

    can greet with InfoKiosk entry {
        print(f"[{here.kiosk_name}] Welcome to the park, {self.party}!");
        visit [-->];
    }
}

walker Zookeeper {
    has keeper: str = "Alex";

    can start with Root entry {
        visit [-->];
    }

    can pass_kiosk with InfoKiosk entry {
        print(f"[{here.kiosk_name}] Welcome to the park, zookeeper {self.keeper}!");
        visit [-->];
    }
}

walker SchoolGroup {
    has class_name: str = "Class 3B";

    can start with Root entry {
        visit [-->];
    }

    can greet with InfoKiosk entry {
        print(f"[{here.kiosk_name}] Welcome to the park, {self.class_name}!");
        visit [-->];
    }
}

with entry {
    kiosk = InfoKiosk(kiosk_name="Front Gate");
    root ++> kiosk
        ++> Lion(species="lion", name="Leo")
        ++> Parrot(species="parrot", name="Polly")
        ++> Animal(species="zebra", name="Zara");

    root spawn Visitor(party="tourists");
    root spawn Zookeeper(keeper="Alex");
    root spawn SchoolGroup(class_name="Class 3B");
}