"""Suggest profiles to follow: keep users not already followed and not the current user, as a list comprehension."""

obj UserView {
    has id: str;
}

def compute_to_follow(allProfiles: list[UserView], followingIds: list[str], myProfileId: str) -> list[UserView] {
    return [
        u
        for u in allProfiles
        if u.id not in followingIds and u.id != myProfileId
    ];
}

with entry {
    profiles = [
        UserView(id="me"),
        UserView(id="a"),
        UserView(id="b"),
        UserView(id="c"),
        UserView(id="d")
    ];
    followingIds = ["b", "d"];
    myProfileId = "me";
    result = compute_to_follow(profiles, followingIds, myProfileId);
    ids = [u.id for u in result];
    print("suggest=" + ",".join(ids) + " count=" + str(len(ids)));
}
