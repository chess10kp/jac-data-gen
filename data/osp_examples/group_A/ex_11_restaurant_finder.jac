"""Restaurant finder: spawning a walker with parameters.

The same finder walker is spawned twice with different minimum
ratings, so the caller decides the search criteria at spawn time.
"""

node Restaurant {
    has name: str = "";
    has rating: float = 0.0;
    has cuisine: str = "";
}

walker Finder {
    has min_rating: float = 3.0;
    has matches: list[str] = [];

    can start with Root entry {
        print(f"Searching for restaurants rated {self.min_rating}+");
        visit [-->];
    }

    can evaluate with Restaurant entry {
        if here.rating >= self.min_rating {
            self.matches.append(here.name);
            print(f"  match: {here.name} ({here.cuisine}, {here.rating})");
        }
        visit [-->];
    }
}

with entry {
    root ++> Restaurant(name="Pasta Palace", rating=4.6, cuisine="Italian")
        ++> Restaurant(name="Burger Barn", rating=3.9, cuisine="American")
        ++> Restaurant(name="Sushi Spot", rating=4.8, cuisine="Japanese")
        ++> Restaurant(name="Taco Truck", rating=3.2, cuisine="Mexican");

    root spawn Finder(min_rating=4.5);
    print("---");
    root spawn Finder(min_rating=3.5);
}
