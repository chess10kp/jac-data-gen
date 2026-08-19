"""RL driver (graph): social_graph.like_tweet.act.

Origin: this_is_jac/littlex/social_graph.jac. `like_tweet` subclasses
`find_tweet` (which resolves the actor + navigates to the target Tweet by jid),
then toggles the actor's like on entry. The marked body is the `act` ability;
the entry block builds a fixed tweet and prints the deterministic like result.
"""

edge Post {}
node Profile { has username: str = ""; }
node Tweet {
    has content: str = "",
        author_username: str = "",
        likes: list[str] = [];
}

walker find_tweet {
    has tweet_id: str = "", actor: str = "";

    can run with Root entry {
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
    }
}

walker like_tweet(find_tweet) {
    can act with Tweet entry {
        # >>>HOLE id="graph_like_tweet_act" instruction="Implement the `act` ability (walker like_tweet, on Tweet entry). Only act when jid(here) == self.tweet_id. Toggle self.actor in here.likes: if already present, remove it and report {'liked': False, 'likes': here.likes}; otherwise append it and report {'liked': True, 'likes': here.likes}. Reassign here.likes (do not mutate in place) and disengage after reporting."
        if jid(here) == self.tweet_id {
            if self.actor in here.likes {
                here.likes = [u for u in here.likes if u != self.actor];
                report {"liked": False, "likes": here.likes};
            } else {
                here.likes = here.likes + [self.actor];
                report {"liked": True, "likes": here.likes};
            }
            disengage;
        }
        # <<<HOLE
    }
}

with entry {
    p = (root ++> Profile(username="alice"))[0];
    t = (p ++> Tweet(content="hello", author_username="alice"))[0];
    tid = jid(t);
    r1 = root spawn like_tweet(tweet_id=tid);
    r2 = root spawn like_tweet(tweet_id=tid);
    print("like:", r1.reports[0]);
    print("unlike:", r2.reports[0]);
}
