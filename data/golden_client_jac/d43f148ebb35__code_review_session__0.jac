walker FriendFinder {
    has started: bool = False;

    can find with `root entry {
        self.started = True;
        visit [-->];
    }
}
