"""Treasure hunt: disengage stops the whole search.

The searcher explores rooms one by one and terminates immediately
when it finds the vault room -- no further rooms are visited after
the treasure is found.
"""

node Room {
    has name: str = "";
    has has_treasure: bool = False;
}

walker TreasureHunter {
    has rooms_checked: int = 0;

    can start with Root entry {
        print("Entering the dungeon...");
        visit [-->];
    }

    can search with Room entry {
        self.rooms_checked += 1;
        if here.has_treasure {
            print(f"Found the treasure in {here.name}!");
            print(f"It took {self.rooms_checked} rooms.");
            disengage;
        }
        print(f"{here.name}: nothing here, moving on");
        visit [-->];
    }
}

with entry {
    root ++> Room(name="Entrance Hall")
        ++> Room(name="Library")
        ++> Room(name="Vault", has_treasure=True)
        ++> Room(name="Dining Hall")
        ++> Room(name="Dungeon Cells");

    root spawn TreasureHunter();
}
