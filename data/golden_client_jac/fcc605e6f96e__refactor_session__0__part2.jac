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
    can start with Root entry;
    can find_recommendations with User entry {
        print(f"Finding recommendations for {here.username}...");
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
walker InterestMatcher {
    has target_interest: str;
    has matches: list = [];
    has visited: list = [];
    can start with Root entry;
    can find with User entry;
}
impl FriendRecommender.start {
    visit [-->];
}
impl InterestMatcher.start {
    visit [-->];
}
impl InterestMatcher.find {
    if here not in self.visited {
        self.visited.append(here);
        if self.target_interest in here.interests {
            self.matches.append(here.username);
        }
    }
}
with entry {
    alice = User(username="alice", age=25, interests=["coding", "hiking", "photography"]);
    bob = User(username="bob", age=28, interests=["coding", "gaming"]);
    charlie = User(username="charlie", age=26, interests=["hiking", "reading"]);
    dana = User(username="dana", age=27, interests=["photography", "travel"]);
    root ++> alice;
    root ++> bob;
    root ++> charlie;
    root ++> dana;
    alice +>:Friendship(since=2020, strength=8):+> bob;
    bob +>:Friendship(since=2020, strength=8):+> alice;
    bob +>:Friendship(since=2021, strength=6):+> charlie;
    charlie +>:Friendship(since=2021, strength=6):+> bob;
    alice +>:Friendship(since=2019, strength=9):+> dana;
    dana +>:Friendship(since=2019, strength=9):+> alice;
    recommender = FriendRecommender();
    bob spawn recommender;
    print(f"Recommendations: {recommender.recommendations}");
    matcher = InterestMatcher(target_interest="hiking");
    root spawn matcher;
    print(f"Users interested in hiking: {matcher.matches}");
}
