obj Greeter {
    has greeting: str;

    def greet(name: str) -> str { return self.greeting + ", " + name; }
}

with entry {
    g = Greeter(greeting="Hola");
    print(g.greet("Bob"));
}
