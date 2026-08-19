# Traditional OOP approach
obj Person {
    has name: str;
    has friends: list[Person] = [];  # List of other Person objects

    def add_friend(person: Person) {
        self.friends.append(person);
        person.friends.append(self);  # Make it mutual
    }
}

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    charlie = Person(name="Charlie");

    # Create friendships manually
    alice.add_friend(bob);
    alice.add_friend(charlie);
    bob.add_friend(charlie);

    # Find friends manually
    print(f"{alice.name}'s friends:");
    for friend in alice.friends {
        print(f"  - {friend.name}");
    }
}
