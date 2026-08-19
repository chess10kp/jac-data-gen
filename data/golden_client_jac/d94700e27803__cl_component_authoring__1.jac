"""RL driver (pure-lib): app.toFollow (suggest profiles the user does not yet follow).

Origin: this_is_jac/littlex/frontend.cl.jac (the toFollow list-comprehension inside the
app render, isolated from JSX and lifted into a standalone def). UserView is inlined as a
minimal obj carrying only the id used by the filter. Deterministic: pure list filtering
over fixed inputs, no IO/time/random. The marked body is the unit the policy must
regenerate; the with entry block exercises it on fixed inputs and prints a deterministic
projection.
"""

obj UserView {
    has id: str;
}

def compute_to_follow(allProfiles: list[UserView], followingIds: list[str], myProfileId: str) -> list[UserView] {
    # >>>HOLE id="lib_to_follow_filter" instruction="Return the sublist of allProfiles to suggest following: keep each user whose id is not present in followingIds AND whose id is not equal to myProfileId. Preserve original order. Build it as a list comprehension."
    return [
        u
        for u in allProfiles
        if u.id not in followingIds and u.id != myProfileId
    ];
    # <<<HOLE
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
