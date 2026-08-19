obj Profile {
    has settings: dict = {};
}

obj User {
    has profile: Profile | None = None;
}

def example(item: User | None, user: User | None) {
    # Without null-safe: raises AttributeError if item is None
    value = item.profile;

    # With null-safe: returns None if item is None
    value = item?.profile;

    # Chained - stops at first None
    result = user?.profile?.settings;
}
