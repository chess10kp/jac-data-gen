node Dog {
    has name: str;
}

node Cat {
    has indoor: bool;
}

node Person {
    has age: int;
}

def example(animals: list) {
    dogs = animals[?:Dog];                    # By type only
    indoor_cats = animals[?:Cat, indoor==True]; # Type with condition
    people = [-->][?:Person];                 # On graph traversal
    adults = [-->][?:Person, age > 21];        # Traversal with condition
}
