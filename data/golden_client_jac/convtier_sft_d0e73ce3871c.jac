obj NameTag {
    has name: str;

    def greet() -> str { return "Hi, " + self.name; }
}

with entry {
    tag = NameTag(name="Bob");
    print(tag.greet());
}
