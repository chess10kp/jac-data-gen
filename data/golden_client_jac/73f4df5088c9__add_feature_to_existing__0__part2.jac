obj User {
    has name: str = "";
    has is_active: bool = True;
    has role: str = "member";
}

def example(user: User | None) -> str {
    name = user?.name or "Anonymous";

    if user?.is_active {
        print(user);
    }

    # New: null-safe role lookup with a fallback
    role = user?.role or "guest";
    return f"{name} ({role})";
}

with entry {
    print(example(None));
    print(example(User(name="Ada", role="admin")));
}
