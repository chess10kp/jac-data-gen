obj Profile {
    has settings: dict = {};
}

obj User {
    has profile: Profile | None = None;
}

def example(item: User | None, user: User | None) -> None {
    value = item?.profile;
    result = user?.profile?.settings;

    # New: null-safe access with a default fallback
    settings = user?.profile?.settings or {};
    print(len(settings));
}

with entry {
    example(None, User(profile=Profile(settings={"theme": "dark"})));
}
