node Person {
    has name: str;
    has age: int = 0;

    can greet with Visitor entry {
        print(f"Hello from {self.name}");
    }
}

node Waypoint { }

walker Visitor {
    can start with Root entry {
        visit [-->];
    }
}
