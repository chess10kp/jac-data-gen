"""RL driver (graph): social_graph.find_profile.run.

Origin: this_is_jac/littlex/social_graph.jac. `find_profile` is the lookup base
walker: given a target_id it resolves the node via jobj and, only when that node
is a Profile, visits it directly so action subclasses can react. The marked body
is the `run` ability; a tiny subclass reports the username of the profile it
lands on. The entry block resolves the real jid of a fixed profile and prints a
deterministic landed/username projection (the random jid itself is never
printed).
"""

node Profile { has username: str = ""; }
node Tweet { has content: str = ""; }

walker find_profile {
    has target_id: str = "";

    can run with Root entry {
        # >>>HOLE id="sg_find_profile_run" instruction="Implement the run ability (walker find_profile, on Root entry). Only when self.target_id is set, resolve target = jobj(self.target_id); if that resolved object isinstance Profile, visit [target]."
        if self.target_id {
            target = jobj(self.target_id);
            if isinstance(target, Profile) {
                visit [target];
            }
        }
        # <<<HOLE
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
