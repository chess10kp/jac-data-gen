"""Switch a warehouse robot's locomotion mid-mission.

A robot crosses floor tiles with Roll edges but must climb stairs via
Climb edges. The mission plan is a dict mapping each stage to an edge
class; the walker reads the class out of the table into a variable and
uses it as the edge type of the hop.
"""

node Cell {
    has label: str;
}

edge Roll {
    has metres: float;
}

edge Climb {
    has steps: int;
}

walker Robot {
    has plan: dict = {};
    has log: list[str] = [];

    can start with Root entry {
        visit [-->];
    }

    can act with Cell entry {
        self.log.append(here.label);

        if here.label in self.plan {
            # Edge types are values: read the class out of the table
            # into a bare variable, then use it in the traversal
            t = self.plan[here.label];
            kind = "climb" if t == Climb else "roll";
            ahead = [->:t:->];
            if ahead {
                print(f"At {here.label}: {kind} toward {ahead[0].label}");
                visit [->:t:->];
            } else {
                print(f"At {here.label}: no {kind} route onward");
            }
        } else {
            print(f"At {here.label}: mission complete");
        }
    }

    can finish with Root exit {
        print("Robot path: " + " -> ".join(self.log));
    }
}

with entry {
    dock = Cell(label="Dock");
    aisle1 = Cell(label="Aisle 1");
    mezzanine = Cell(label="Mezzanine");
    packing = Cell(label="Packing Bench");

    root ++> dock;
    dock +>: Roll(metres=14.5) :+> aisle1;
    aisle1 +>: Climb(steps=18) :+> mezzanine;
    mezzanine +>: Roll(metres=7.0) :+> packing;

    bot = Robot(plan={"Dock": Roll, "Aisle 1": Climb, "Mezzanine": Roll});
    root spawn bot;
}
