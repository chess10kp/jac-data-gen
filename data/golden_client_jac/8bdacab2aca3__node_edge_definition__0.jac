"""RL driver (graph): social_graph.unfollow_user.act.

Origin: this_is_jac/littlex/social_graph.jac. `unfollow_user` subclasses
`find_profile` (resolves the target Profile by jid) and `act` deletes the
Follow edge from the caller's profile to the target. The marked body is `act`;
the entry block pre-wires a follow, unfollows, and prints success + remaining.
"""

edge Follow {}

node Profile { has username: str = ""; }

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

walker unfollow_user(find_profile) {
    can act with Profile entry {
        # >>>HOLE id="sg_unfollow_user_act" instruction="Implement the act ability (walker unfollow_user, on Profile entry). Only act when jid(here) == self.target_id. Resolve the caller's profile me = [root-->[?:Profile]][0], collect edges = [edge me->:Follow:->here], and if any exist delete the first with del edges[0]. Report {'success': True} then disengage."
        if jid(here) == self.target_id {
            me = [root-->[?:Profile]][0];
            edges = [edge me->:Follow:->here];
            if edges {
                del edges[0];
            }
            report {"success": True};
            disengage;
        }
        # <<<HOLE
    }
}

walker list_following {
    has names: list[str] = [], reports: list[list[str]] = [];
    can run with Root entry { visit [-->[?:Profile]]; }
    can gather with Profile entry {
        if here.username == "alice" {
            self.names = [p.username for p in [here->:Follow:->[?:Profile]]];
        }
    }
    can deliver with Root exit { report self.names; }
}

with entry {
    alice = (root ++> Profile(username="alice"))[0];
    bob = (root ++> Profile(username="bob"))[0];
    alice +>: Follow() :+> bob;
    bid = jid(bob);
    res = root spawn unfollow_user(target_id=bid);
    print("result:", res.reports[0]);
    chk = root spawn list_following();
    print("alice_following:", sorted(chk.reports[0]));
}
