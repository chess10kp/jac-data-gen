def helper() -> str {
    return "I'm a helper";
}

def farewell(name: str) -> str {
    return f"Goodbye, {name}!";
}

with entry {
    print(helper());
    print(farewell("Alice"));
}
