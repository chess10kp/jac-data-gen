node Person {
    has name: str;
    can announce with FriendFinder entry {
        print(f"{visitor} is checking me out");
    }
}

edge Friend {}
edge Family {
    can announce with FriendFinder entry {
        print(f"{visitor} is traveling to family member");
    }
}
