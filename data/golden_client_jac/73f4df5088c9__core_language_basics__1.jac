obj User {
    has name: str = "";
    has is_active: bool = True;
}

def example(user: User | None) {
    # Null-safe with fallback using or
    name = user?.name or "Anonymous";

    # In conditionals
    if user?.is_active {
        print(user);
    }
}
