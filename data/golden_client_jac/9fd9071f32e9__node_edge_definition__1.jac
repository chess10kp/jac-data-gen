"""RL driver (graph): social_graph.get_trending.tally.

Origin: this_is_jac/littlex/social_graph.jac. An object-spatial walker that
fans out over a profile's tweets, tallies hashtags (deduped by tweet identity),
and reports the top tags. The marked body is the `tally` ability; the entry
block builds a fixed graph and prints a deterministic (tag, count) projection.
"""

obj TrendingTag {
    has tag: str, count: int;
}
edge Post {}
node Profile { has username: str = ""; }
node Tweet { has content: str = ""; }

walker get_trending {
    has counts: dict[str, int] = {},
        seen: dict[str, bool] = {},
        reports: list[list[TrendingTag]] = [];

    can run with Root entry {
        for r in allroots() {
            visit [r-->[?:Profile]-->[?:Tweet]];
        }
    }

    can tally with Tweet entry {
        # >>>HOLE id="graph_trending_tally" instruction="Implement the `tally` ability (walker get_trending, on Tweet entry). Dedupe by tweet identity using jid(here) against self.seen (return early if already seen, else mark seen). Then for each whitespace word in here.content that startswith('#') and has length > 1, normalise it with word.lower().rstrip('.,!?;:') and increment self.counts[tag] (default 0)."
        tid = jid(here);
        if tid in self.seen {
            return;
        }
        self.seen[tid] = True;
        for word in here.content.split() {
            if word.startswith("#") and len(word) > 1 {
                tag = word.lower().rstrip(".,!?;:");
                self.counts[tag] = self.counts.get(tag, 0) + 1;
            }
        }
        # <<<HOLE
    }

    can deliver with Root exit {
        tags = [TrendingTag(tag=t, count=self.counts[t]) for t in self.counts];
        tags.sort(key=lambda x: TrendingTag : x.count, reverse=True);
        report tags[:8];
    }
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
