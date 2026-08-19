node Dog {
    has name: str;
}

node Cat {
    has indoor: bool;
}

node Person {
    has age: int;
}

node Bird {
    has can_fly: bool;
}

def example(animals: list) {
    dogs = animals[?:Dog];                    # By type only
    indoor_cats = animals[?:Cat, indoor==True]; # Type with condition
    people = [-->][?:Person];                 # On graph traversal
    adults = [-->][?:Person, age > 21];        # Traversal with condition
    birds = animals[?:Bird];                   # New: filter by Bird type
    flyers = animals[?:Bird, can_fly==True];   # Bird type with condition
}
