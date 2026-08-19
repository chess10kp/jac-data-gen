"""RL driver (graph): social_graph.delete_tweet.act.

Origin: this_is_jac/littlex/social_graph.jac. `delete_tweet` subclasses
`find_tweet` (resolves the actor + navigates to the target Tweet by jid) and
`act` deletes the tweet if the actor is its author. The marked body is `act`;
the entry block deletes one of two tweets and prints success + remaining count.
"""

node Profile { has username: str = ""; }
node Tweet {
    has content: str = "", author_username: str = "";
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

walker delete_tweet(find_tweet) {
    can act with Tweet entry {
        # >>>HOLE id="sg_delete_tweet_act" instruction="Implement the act ability (walker delete_tweet, on Tweet entry). Only act when jid(here) == self.tweet_id AND here.author_username == self.actor. Delete the current node with del here, report {'success': True}, then disengage."
        if jid(here) == self.tweet_id and here.author_username == self.actor {
            del here;
            report {"success": True};
            disengage;
        }
        # <<<HOLE
    }
}

walker count_tweets {
    has n: int = 0, contents: list[str] = [], reports: list[list[str]] = [];
    can run with Root entry { visit [-->[?:Profile]-->[?:Tweet]]; }
    can tally with Tweet entry { self.contents.append(here.content); }
    can deliver with Root exit { report self.contents; }
}

with entry {
    p = (root ++> Profile(username="alice"))[0];
    t1 = (p ++> Tweet(content="first", author_username="alice"))[0];
    p ++> Tweet(content="second", author_username="alice");
    tid = jid(t1);
    res = root spawn delete_tweet(tweet_id=tid);
    print("result:", res.reports[0]);
    chk = root spawn count_tweets();
    print("remaining:", sorted(chk.reports[0]));
    print("remaining_count:", len(chk.reports[0]));
}
