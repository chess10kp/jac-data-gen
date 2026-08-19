"""RL driver (graph): social_graph.get_channels.deliver.

Origin: this_is_jac/littlex/social_graph.jac. `get_channels` fans out over every
root's channels, dedupes them by jid into self.results, and the `deliver` ability
sorts the gathered channel views by descending created_at before reporting them.
The marked body is `deliver`; the entry block builds two channels with fixed
created_at literals and prints a deterministic name-ordering projection. View ids
are emitted as empty strings.
"""

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

node Profile { has username: str = ""; }
node Channel {
    has name: str = "", description: str = "", creator_username: str = "",
        created_at: str = "";

    def to_view(with_posts: bool) -> ChannelView {
        mine = [root-->[?:Profile]];
        is_member: bool = len(mine) > 0 and len([edge mine[0]->:Member:->self]) > 0;
        return ChannelView(
            id="", name=self.name, description=self.description,
            creator_username=self.creator_username, created_at=self.created_at,
            member_count=len([self<-:Member:<-[?:Profile]]),
            is_member=is_member, posts=[]
        );
    }
}

walker get_channels {
    has seen: dict[str, bool] = {}, results: list[ChannelView] = [],
        reports: list[list[ChannelView]] = [];

    can run with Root entry {
        for r in allroots() {
            visit [r-->[?:Profile]-->[?:Channel]];
        }
    }

    can gather with Channel entry {
        cid = jid(here);
        if cid not in self.seen {
            self.seen[cid] = True;
            self.results.append(here.to_view(False));
        }
    }

    can deliver with Root exit {
        # >>>HOLE id="sg_get_channels_deliver" instruction="Implement the deliver ability (walker get_channels, on Root exit). Sort self.results in place by the created_at field in descending order, then report self.results."
        self.results.sort(key=lambda c: ChannelView : c.created_at, reverse=True);
        report self.results;
        # <<<HOLE
    }
}

with entry {
    p = (root ++> Profile(username="alice"))[0];
    p +>: Member() :+> Channel(name="early", creator_username="alice", created_at="2020-01-01T00:00:00Z");
    p +>: Member() :+> Channel(name="late", creator_username="alice", created_at="2020-02-01T00:00:00Z");
    res = root spawn get_channels();
    print("names_desc_by_date:", [c.name for c in res.results]);
    print("count:", len(res.results));
}
