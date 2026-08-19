"""RL driver (graph): social_graph.add_comment.act.

Origin: this_is_jac/littlex/social_graph.jac. `add_comment` subclasses
`find_tweet` (resolves the actor + navigates to the target Tweet by jid) and
`act` appends a comment dict to the tweet. The marked body is `act`; the entry
block adds a comment and prints the comment's username + content. The comment's
created_at is a fixed literal so the auto-printed report stays deterministic.
"""

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
        # >>>HOLE id="sg_add_comment_act" instruction="Implement the act ability (walker add_comment, on Tweet entry). Only act when jid(here) == self.tweet_id. Build a comment dict with keys username=self.actor, content=self.content, created_at set to the literal string 2020-01-01T00:00:00Z. Append it (reassign here.comments = here.comments + [comment]), report {'success': True, 'comment': comment}, then disengage."
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
        # <<<HOLE
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
