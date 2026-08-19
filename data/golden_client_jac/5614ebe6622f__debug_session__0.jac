with entry {
    name: str = "My Day Planner";
    version: int = 1;
    rating: float = 4.5;
    ready: bool = True;

    # Type can be inferred from the value
    greeting = f"Welcome to {name} v{version}!";
    print(greeting);
}
