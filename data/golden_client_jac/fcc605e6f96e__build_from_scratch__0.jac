node User {
    has username: str;
    has age: int;
    has interests: list;
}

edge Friendship {
    has since: int;
    has strength: int = 1;
}

walker FriendRecommender {
    has recommendations: list = [];
    can find_recommendations with User entry {
        potential_friends = [here ->:Friendship:-> ->:Friendship:->];
        current_friends = [here ->:Friendship:->];
        for person in potential_friends {
            if person not in current_friends and person != here {
                self.recommendations.append(person.username);
            }
        }
        disengage;
    }
}
