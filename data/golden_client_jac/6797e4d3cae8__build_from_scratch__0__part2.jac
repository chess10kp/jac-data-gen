"""find_tweet.run: capture the caller's profile username into actor, then resolve and visit the Tweet."""

node Profile { has username: str = ""; }
node Tweet { has content: str = "", author_username: str = ""; }

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
