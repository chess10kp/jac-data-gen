"""Shortest connection path between two people in a network.

Runs a breadth-first search from a source person to a target person using
the walker's queue-based traversal, recording each person's parent when
first discovered, then reconstructs the chain of introductions.
"""

node Person {
    has name: str;
}

edge Knows: Person --> Person {}

walker PathFinder {
    has goal: str;
    has start_name: str = "";
    has parents: dict = {};
    has found_path: list[str] = [];

    can search with Person entry {
        if self.start_name == "" {
            self.start_name = here.name;
        }

        # Found the target: walk the parent links back to the start.
        if here.name == self.goal {
            path = [];
            cursor = here;
            while cursor.name != self.start_name {
                path.append(cursor.name);
                cursor = self.parents[cursor.name];
            }
            path.append(self.start_name);
            path.reverse();
            self.found_path = path;
            disengage;
        }

        # Enqueue undiscovered neighbours; the visit queue gives us
        # breadth-first order, so the first arrival is a shortest path.
        for neighbor in [->:Knows:->] {
            if neighbor.name == self.start_name or neighbor.name in self.parents {
                continue;
            }
            self.parents[neighbor.name] = here;
            visit neighbor;
        }
    }
}

with entry {

    # Reset leftovers from any previous run of this demo.
    for stale_node in [root -->][?:Person] {
        del stale_node;
    }
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    carol = Person(name="Carol");
    dave = Person(name="Dave");
    erin = Person(name="Erin");
    frank = Person(name="Frank");

    alice +>: Knows() :+> bob;
    alice +>: Knows() :+> carol;
    bob +>: Knows() :+> dave;
    carol +>: Knows() :+> dave;
    dave +>: Knows() :+> erin;
    erin +>: Knows() :+> frank;

    result = alice spawn PathFinder(goal="Frank");
    if result.found_path {
        print(f"Shortest introduction chain ({len(result.found_path) - 1} hops):");
        print("  " + " -> ".join(result.found_path));
    } else {
        print("No connection path found.");
    }
}
