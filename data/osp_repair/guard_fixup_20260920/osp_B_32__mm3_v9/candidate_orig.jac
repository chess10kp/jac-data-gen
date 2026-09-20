"""Wildlife park feeding rounds.

The info kiosk greets every tour party. Zookeepers feed each animal its
species-appropriate meal. School groups just watch the animals.
"""

node InfoKiosk {
    has kiosk_name: str = "";

    can greet with Zookeeper | SchoolGroup entry {
        print(f"Welcome to {self.kiosk_name}!");
        visitor.kiosk_visited = True;
    }
}

node Animal {
    has species: str = "";
    has name: str = "";

    def standard_meal() -> str {
        return "standard feed";
    }
}

node Lion(Animal) {
    override def standard_meal() -> str {
        return "meat";
    }
}

node Parrot(Animal) {
    override def standard_meal() -> str {
        return "seed";
    }
}

walker Zookeeper {
    has zookeeper_name: str = "";
    has kiosk_visited: bool = False;

    can start with Root entry {
        print(f"Zookeeper {self.zookeeper_name} begins feeding rounds");
        visit [-->];
    }

    can greet_kiosk with InfoKiosk entry {
        visit [-->];
    }

    can feed with Animal entry {
        print(f"[Zookeeper {self.zookeeper_name}] Feeding {here.name} the {here.species}: {here.standard_meal()}");
        visit [-->];
    }
}

walker SchoolGroup {
    has group_name: str = "";
    has kiosk_visited: bool = False;

    can start with Root entry {
        print(f"School group {self.group_name} is watching the animals");
        visit [-->];
    }

    can greet_kiosk with InfoKiosk entry {
        visit [-->];
    }

    can observe with Animal entry {
        print(f"[School group {self.group_name}] Watching {here.name} the {here.species}");
        visit [-->];
    }
}

with entry {
    kiosk = InfoKiosk(kiosk_name="Safari Info");
    simba = Lion(species="Lion", name="Simba");
    polly = Parrot(species="Parrot", name="Polly");
    bunny = Animal(species="Rabbit", name="Bunny");

    root ++> kiosk ++> simba ++> polly ++> bunny;

    zk = Zookeeper(zookeeper_name="Alex");
    root spawn zk;

    sg = SchoolGroup(group_name="Oak Elementary");
    root spawn sg;
}