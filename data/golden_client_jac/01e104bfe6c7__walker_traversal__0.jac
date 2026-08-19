walker FriendFinder {
    can find with Root entry {
        visit [-->];
    }
}

with entry {
    result = FriendFinder() spawn root;
}
