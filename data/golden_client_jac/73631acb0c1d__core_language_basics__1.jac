obj Person {
    has name: str;                    # Required
    has age: int = 0;                 # With default
    static has count: int = 0;        # Static (class-level)
}
