obj Person {
    has name: str;
    has friends: list[Person] = [];

    def add_friend(person: Person) {
        self.friends.append(person);
        person.friends.append(self);
    }
}

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    alice.add_friend(bob);
}
