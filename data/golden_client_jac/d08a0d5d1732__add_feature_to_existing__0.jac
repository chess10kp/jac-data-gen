obj Person {
    has name: str;
    has age: int;
    has email: str;

    def contact() -> str {
        return self.email if self.email else "no email";
    }
}
