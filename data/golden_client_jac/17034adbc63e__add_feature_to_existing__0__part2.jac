obj Person {
    has name: str;
    has age: int;
    has bio: str | None;
    has email: str | None;
}

sem Person.email = "The person's email address if mentioned in the text, otherwise null.";

def extract_person(text: str) -> Person by llm();
