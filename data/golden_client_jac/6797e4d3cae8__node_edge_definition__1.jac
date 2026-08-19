"""RL driver (graph): social_graph.find_tweet.run.

Origin: this_is_jac/littlex/social_graph.jac. `find_tweet` is the lookup base
walker: it records the caller's own username as `actor`, then given a tweet_id
resolves the node via jobj and, only when that node is a Tweet, visits it. The
marked body is the `run` ability; a tiny subclass reports the content of the
tweet it lands on plus the resolved actor. The entry block resolves the real jid
of a fixed tweet and prints a deterministic projection (the random jid itself is
never printed).
"""

node Profile { has username: str = ""; }
node Tweet { has content: str = "", author_username: str = ""; }

walker find_tweet {
    has tweet_id: str = "", actor: str = "";

    can run with Root entry {
        # >>>HOLE id="sg_find_tweet_run" instruction="Implement the run ability (walker find_tweet, on Root entry). Resolve the caller's profile mine = [-->[?:Profile]]; if mine is non-empty set self.actor to mine[0].username. Then only when self.tweet_id is set, resolve target = jobj(self.tweet_id); if that object isinstance Tweet, visit [target]."
        mine = [-->[?:Profile]];
        if mine {
            self.actor = mine[0].username;
        }
        if self.tweet_id {
            target = jobj(self.tweet_id);
            if isinstance(target, Tweet) {
                visit [target];
            }
        }
        # <<<HOLE
    }
}

walker check_tweet(find_tweet) {
    has landed_content: str = "", landed: bool = False;

    can act with Tweet entry {
        self.landed = True;
        self.landed_content = here.content;
        disengage;
    }
}

with entry {
    me = (root ++> Profile(username="alice"))[0];
    tw = (me ++> Tweet(content="hello world", author_username="alice"))[0];

    # Resolves to the tweet -> lands; actor read from caller's profile.
    r1 = root spawn check_tweet(tweet_id=jid(tw));
    print("tweet_landed:", r1.landed);
    print("tweet_content:", r1.landed_content);
    print("actor:", r1.actor);

    # A profile jid is not a Tweet -> never visits, but actor still resolved.
    r2 = root spawn check_tweet(tweet_id=jid(me));
    print("profile_landed:", r2.landed);
    print("profile_actor:", r2.actor);

    # Empty target -> never visits.
    r3 = root spawn check_tweet();
    print("empty_landed:", r3.landed);
}
