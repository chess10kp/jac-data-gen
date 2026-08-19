node Person {
    has name: str;
}
edge Friend {
    has since: int;
}
walker FriendQuery {
    can run with Person entry {
        all_friends = [here -->];
        print(f"{here.name} has {len(all_friends)} friends");
        friends = [here ->:Friend:->];
        for friend in friends {
            print(friend.name);
        }
        old_friends = [here ->:Friend:since < 2018:->];
    }
}
with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    charlie = Person(name="Charlie");
    alice +>:Friend(since=2015):+> bob;
    alice +>:Friend(since=2020):+> charlie;
    alice spawn FriendQuery();
}
