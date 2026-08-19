"""add_comment walker: on the target Tweet, append a comment dict and report it, persisting via field reassignment."""

node Profile { has username: str = ""; }
node Tweet {
    has content: str = "", author_username: str = "", comments: list[dict[str, str]] = [];
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

walker add_comment(find_tweet) {
    has content: str = "";

    can act with Tweet entry {
        if jid(here) == self.tweet_id {
            comment = {
                "username": self.actor,
                "content": self.content,
                "created_at": "2020-01-01T00:00:00Z"
            };
            here.comments = here.comments + [comment];
            report {"success": True, "comment": comment};
            disengage;
        }
    }
}

with entry {
    p = (root ++> Profile(username="alice"))[0];
    t = (p ++> Tweet(content="hello", author_username="alice"))[0];
    tid = jid(t);
    res = root spawn add_comment(tweet_id=tid, content="nice post");
    c = res.reports[0]["comment"];
    print("success:", res.reports[0]["success"]);
    print("comment_username:", c["username"]);
    print("comment_content:", c["content"]);
    print("comment_count:", len(t.comments));
}
