def greet(name: str = "friend", excited: bool = False) {
    if excited {
        print(f"HELLO, {name}!!!");
    } else {
        print(f"Hello, {name}.");
    }
}

with entry {
    greet();                          # Uses defaults
    greet("Alice");                   # Uses name, default excited
    greet("Bob", True);               # Both specified
    greet(excited=True, name="Eve");  # Named parameters
}
