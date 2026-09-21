"""Social feed with timed follows.

``Follow`` declares typed endpoints (Profile --> Profile); the subtype
edge ``TimedFollow(Follow)`` inherits those endpoints and only adds a
timestamp. A separate ``Posted: Profile --> Tweet`` edge carries posts.
Because endpoints are declared, traversals infer concrete node types
without extra filters, and the TimedFollow edge's own ability fires
only because the bot visits edges explicitly with ``visit [edge -->]``.
"""

node Profile {
    has handle: str;
}

node Tweet {
    has text: str;
}

edge Follow: Profile --> Profile {}

edge TimedFollow(Follow) {
    has since: str = "";

    # Edge abilities wake only when the itinerary includes the edge,
    # i.e. on `visit [edge -->]`, never on a plain `visit [-->]`.
    can stamp with FeedBot entry {
        print(f"  (follow active since {self.since})");
    }
}

edge Posted: Profile --> Tweet {}

walker FeedBot {
    has seen_posts: int = 0;
    has seen_handles: list[str] = [];

    can start with Root entry {
        visit [-->];
    }

    can crawl with Profile entry {
        if here.handle in self.seen_handles {
            skip;  # already crawled from another path
        }
        self.seen_handles.append(here.handle);
        print(f"profile @{here.handle}:");
        for peer in [->:TimedFollow:->] {
            print(f"  timed-follows @{peer.handle}");
        }
        for post in [->:Posted:->] {
            self.seen_posts += 1;
            print(f"  posted '{post.text}'");
        }
        # Visit the EDGES themselves so TimedFollow abilities fire.
        visit [edge -->];
    }

    can read with Tweet entry {
        print(f"  (reached tweet via edge traversal)");
    }
}

with entry {
    ana = Profile(handle="ana");
    ben = Profile(handle="ben");
    caro = Profile(handle="caro");
    t1 = Tweet(text="hello graph");
    t2 = Tweet(text="edge types are neat");

    root ++> ana;
    ana +>: Follow() :+> ben;
    ben +>: TimedFollow(since="2021-06-01") :+> caro;
    ana +>: TimedFollow(since="2019-11-23") :+> caro;
    ana +>: Posted() :+> t1;
    ben +>: Posted() :+> t2;

    bot = FeedBot();
    result = root spawn bot;
}
