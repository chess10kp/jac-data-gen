node Person {
    has name: str;
}

walker MyWalker {
    # Runs when walker spawns at root
    can start with Root entry {
        # ...
    }

    # Runs when walker visits ANY Person node
    can meet_person with Person entry {
        # 'here' refers to the current node
        # 'self' refers to the walker
    }

    # Runs when walker is done
    can finish with exit {
        # ...
    }
}
