node Person {
    has name: str;
    has age: int = 0;

    can greet with Visitor entry {
        print(f"Hello from {self.name}");
    }
}

# Node with no data
node Waypoint { }
