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
