node Person {
    has name: str;
    can greet with Visitor entry {
        print(f"{self.name} says: Welcome, visitor!");
    }
}

walker Visitor {
    can meet with Person entry {
        print(f"Visitor says: Hello, {here.name}!");
    }
}
