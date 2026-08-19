node Profile {
    has username: str;
}

node Tweet {
    has content: str;
}

edge Posted {}

# CREATE - each user owns its data under its own root; a socially
# reachable node must be granted so OTHER users can traverse into it.
def:priv post_tweet(content: str) -> str {
    prof = [root --> [?:Profile]][0];
    t = (prof +>:Posted:+> Tweet(content=content))[0];
    grant(t, level=ConnectPerm);          # others may now connect/read this tweet
    return t.content;
}


# CROSS-USER READ - allroots() surfaces every user's root even from a
# per-user def:priv endpoint; you still only see nodes that were granted.
def:priv global_feed() -> list[dict] {
    feed: list[dict] = [];
    for r in allroots() {
        for prof in [r --> [?:Profile]] {
            for tw in [prof ->:Posted:-> [?:Tweet]] {
                feed.append({"by": prof.username, "text": tw.content});
            }
        }
    }
    return feed;
}
