node Animal { has name: str = ""; }
node Dog(Animal) {}
node Cat(Animal) {}

walker AnimalVisitor {
    can greet with Animal entry {
        # Typed context block for Dog (subtype of Animal)
        ->Dog{print(f"{here.name} is a dog");}

        # Typed context block for Cat (subtype of Animal)
        ->Cat{print(f"{here.name} says meow");}

        # Keep walking the graph
        visit [-->];
    }
}
