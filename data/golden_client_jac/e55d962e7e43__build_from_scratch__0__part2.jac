"""find_profile.run: resolve target_id only when set and visit only when it is a Profile."""

node Profile { has username: str = ""; }
node Tweet { has content: str = ""; }

walker find_profile {
    has target_id: str = "";

    can run with Root entry {
        if self.target_id {
            target = jobj(self.target_id);
            if isinstance(target, Profile) {
                visit [target];
            }
        }
    }
}

walker check_profile(find_profile) {
    has landed_username: str = "", landed: bool = False;

    can act with Profile entry {
        self.landed = True;
        self.landed_username = here.username;
        disengage;
    }
}

with entry {
    alice = (root ++> Profile(username="alice"))[0];
    tw = (root ++> Tweet(content="not a profile"))[0];

    # Resolves to the profile -> lands.
    r1 = root spawn check_profile(target_id=jid(alice));
    print("profile_landed:", r1.landed);
    print("profile_username:", r1.landed_username);

    # A tweet jid is not a Profile -> never visits.
    r2 = root spawn check_profile(target_id=jid(tw));
    print("tweet_landed:", r2.landed);

    # Empty target -> never visits.
    r3 = root spawn check_profile();
    print("empty_landed:", r3.landed);
}
