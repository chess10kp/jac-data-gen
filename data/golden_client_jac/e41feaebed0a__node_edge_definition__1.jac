"""RL driver (graph): social_graph.create_channel_tweet.act.

Origin: this_is_jac/littlex/social_graph.jac. `create_channel_tweet` subclasses
`find_channel` (resolves the target Channel by jid) and, when the caller is a
member, attaches a Tweet to the channel via a ChannelPost edge. The marked body
is `act`; the entry block posts to a fixed channel and prints the tweet view.
"""

obj UserView { has id: str, username: str, bio: str = ""; }
obj TweetView {
    has id: str, content: str, author_username: str, created_at: str,
        likes: list[str], comments: list[dict[str, str]], is_mine: bool = False;
}
obj ChannelView {
    has id: str, name: str, description: str, creator_username: str,
        created_at: str, member_count: int, is_member: bool,
        posts: list[TweetView] = [];
}

edge Member {}
edge ChannelPost {}

node Profile { has username: str = ""; }
node Tweet {
    has content: str = "", author_username: str = "", created_at: str = "",
        likes: list[str] = [], comments: list[dict[str, str]] = [];

    def to_view -> TweetView {
        mine = [root-->[?:Profile]];
        is_mine: bool = len(mine) > 0 and self.author_username == mine[0].username;
        return TweetView(
            id="", content=self.content, author_username=self.author_username,
            created_at=self.created_at, likes=self.likes, comments=self.comments, is_mine=is_mine
        );
    }
}
node Channel {
    has name: str = "", description: str = "", creator_username: str = "",
        created_at: str = "";
}

walker find_channel {
    has channel_id: str = "";

    can run with Root entry {
        if self.channel_id {
            target = jobj(self.channel_id);
            if isinstance(target, Channel) {
                visit [target];
            }
        }
    }
}

walker create_channel_tweet(find_channel) {
    has content: str = "";

    can act with Channel entry {
        # >>>HOLE id="sg_create_channel_tweet_act" instruction="Implement the act ability (walker create_channel_tweet, on Channel entry). Only act when jid(here) == self.channel_id. Find the caller's Profile via [root-->[?:Profile]][0]. Only if a Member edge exists from that profile to here, attach a new Tweet to here via a ChannelPost edge, with content=self.content, author_username set to the caller's username, and created_at set to the literal string 2020-01-01T00:00:00Z; grant the new tweet WritePerm and report its view via to_view(). Always disengage at the end."
        if jid(here) == self.channel_id {
            me = [root-->[?:Profile]][0];
            if [edge me->:Member:->here] {
                new = here +>: ChannelPost() :+> Tweet(
                    content=self.content, author_username=me.username, created_at="2020-01-01T00:00:00Z"
                );
                grant(new[0], level=WritePerm);
                report new[0].to_view();
            }
            disengage;
        }
        # <<<HOLE
    }
}

with entry {
    p = (root ++> Profile(username="alice"))[0];
    c = (p +>: Member() :+> Channel(name="jacdevs", creator_username="alice"))[0];
    cid = jid(c);
    res = root spawn create_channel_tweet(channel_id=cid, content="hello channel");
    tv = res.reports[0];
    print("content:", tv.content);
    print("author:", tv.author_username);
    print("is_mine:", tv.is_mine);
    print("likes:", tv.likes);
    print("channel_post_count:", len([c-->[?:Tweet]]));
}
