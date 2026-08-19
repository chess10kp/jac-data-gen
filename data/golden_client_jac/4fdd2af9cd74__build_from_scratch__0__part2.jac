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
