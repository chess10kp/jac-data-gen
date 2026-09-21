"""Office tower tour: walkers that begin at the graph root.

A guided tour spawns at root and only the `with Root entry` ability
kicks off the walk; each floor then handles the visitor itself. This
keeps the starting logic separate from per-location logic.
"""

node Floor {
    has number: int = 0;
    has department: str = "";
}

walker TourGuide {
    has tour_name: str = "Standard Tour";

    can begin with Root entry {
        print(f"-- {self.tour_name} begins --");
        visit [-->];
    }

    can show_floor with Floor entry {
        print(f"Floor {here.number}: {here.department}");
        visit [-->];
    }
}

with entry {
    lobby = Floor(number=1, department="Lobby & Reception");
    eng = Floor(number=2, department="Engineering");
    design = Floor(number=3, department="Design");
    roof = Floor(number=4, department="Rooftop Cafe");

    root ++> lobby ++> eng ++> design ++> roof;

    root spawn TourGuide(tour_name="New Hire Tour");
}
