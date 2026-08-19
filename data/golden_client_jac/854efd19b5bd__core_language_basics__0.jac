# Traditional OOP approach - Have to manually traverse
obj Person {
    has name: str;
    has connections: list = [];
}

obj Connection {
    has conn_type: str;
    has target: object;
}

def find_friends(person: Person) -> list {
    friends = [];
    for connection in person.connections {
        if connection.conn_type == "friend" {
            friends.append(connection.target);
        }
    }
    return friends;
}

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");

    conn = Connection(conn_type="friend", target=bob);
    alice.connections.append(conn);

    friends = find_friends(alice);
    print(f"Found {len(friends)} friend(s)");
    # Verbose, imperative, error-prone
}
