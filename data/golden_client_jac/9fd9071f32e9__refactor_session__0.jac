"""get_trending: hashtag normalization extracted; abilities split into impl blocks."""

obj TrendingTag {
    has tag: str, count: int;
}
edge Post {}
node Profile { has username: str = ""; }
node Tweet { has content: str = ""; }

def _norm_tag(word: str) -> str {
    return word.lower().rstrip(".,!?;:");
}

walker get_trending {
    has counts: dict[str, int] = {},
        seen: dict[str, bool] = {},
        reports: list[list[TrendingTag]] = [];

    can run with Root entry;
    can tally with Tweet entry;
    can deliver with Root exit;
}

impl get_trending.run {
    for r in allroots() {
        visit [r-->[?:Profile]-->[?:Tweet]];
    }
}

impl get_trending.tally {
    tid = jid(here);
    if tid in self.seen {
        return;
    }
    self.seen[tid] = True;
    for word in here.content.split() {
        if word.startswith("#") and len(word) > 1 {
            tag = _norm_tag(word);
            self.counts[tag] = self.counts.get(tag, 0) + 1;
        }
    }
}

impl get_trending.deliver {
    tags = [TrendingTag(tag=t, count=self.counts[t]) for t in self.counts];
    tags.sort(key=lambda x: TrendingTag : x.count, reverse=True);
    report tags[:8];
}

with entry {
    p = (root ++> Profile(username="alice"))[0];
    p ++> Tweet(content="loving #jac and #jac again, also #rl");
    p ++> Tweet(content="#rl scaling with #jac");
    p ++> Tweet(content="no tags here");
    res = root spawn get_trending();
    out = [(t.tag, t.count) for t in res.reports[0]];
    print(out);
}
