# Define our graph structure
node User {
    has username: str;
    has age: int;
    has interests: list;
}

edge Friendship {
    has since: int;
    has strength: int = 1;  # How close they are (1-10)
}

# Walker to recommend friends
walker FriendRecommender {
    has recommendations: list = [];

    can start with Root entry {
        visit [-->];
    }

    # Start from a user
    can find_recommendations with User entry {
        print(f"Finding recommendations for {here.username}...");
        # Visit friends of friends (2 hops)
        potential_friends = [here ->:Friendship:-> ->:Friendship:->];

        # Get current friends to exclude
        current_friends = [here ->:Friendship:->];

        for person in potential_friends {
            # Don't recommend current friends or self
            if person not in current_friends and person != here {
                self.recommendations.append(person.username);
            }
        }
        disengage;
    }
}

# Walker to find users by interest
walker InterestMatcher {
    has target_interest: str;
    has matches: list = [];
    has visited: list = [];

    can start with Root entry {
        visit [-->];
    }

    can find with User entry {
        if here not in self.visited {
            self.visited.append(here);
            if self.target_interest in here.interests {
                self.matches.append(here.username);
            }
        }
    }
}

with entry {
    # Create users
    alice = User(
        username="alice",
        age=25,
        interests=["coding", "hiking", "photography"]
    );

    bob = User(
        username="bob",
        age=28,
        interests=["coding", "gaming"]
    );

    charlie = User(
        username="charlie",
        age=26,
        interests=["hiking", "reading"]
    );

    dana = User(
        username="dana",
        age=27,
        interests=["photography", "travel"]
    );

    # Build social graph
    root ++> alice;
    root ++> bob;
    root ++> charlie;
    root ++> dana;

    # Bidirectional friendships (two directed edges per pair)
    alice +>:Friendship(since=2020, strength=8):+> bob;
    bob +>:Friendship(since=2020, strength=8):+> alice;
    bob +>:Friendship(since=2021, strength=6):+> charlie;
    charlie +>:Friendship(since=2021, strength=6):+> bob;
    alice +>:Friendship(since=2019, strength=9):+> dana;
    dana +>:Friendship(since=2019, strength=9):+> alice;

    # Find friend recommendations for Bob
    recommender = FriendRecommender();
    bob spawn recommender;
    print(f"Recommendations: {recommender.recommendations}");

    # Find users interested in hiking
    matcher = InterestMatcher(target_interest="hiking");
    root spawn matcher;
    print(f"Users interested in hiking: {matcher.matches}");
}
