node User {
    has name: str;
}

node Post {
    has title: str;
    has published: bool = False;
}

edge Wrote {
    has at: str = "";
}


# CREATE - typed edge from user to the new post
def:pub write_post(user_id: str, title: str) -> Post | None {
    for u in [root -->][?:User] {
        if jid(u) == user_id {
            post = Post(title=title);
            u +>:Wrote(at="2026-04-21"):+> post;
            return post;
        }
    }
    return None;
}


# READ - posts written by a specific user (multi-hop through Wrote edges)
def:pub posts_by(user_id: str) -> list[Post] {
    for u in [root -->][?:User] {
        if jid(u) == user_id {
            return [u ->:Wrote:->][?:Post];   # [?:Post] recovers the node type
        }
    }
    return [];
}


# FILTER - posts matching a field predicate
def:pub published_posts() -> list[Post] {
    return [root -->][?:Post][?published];
}


# AGGREGATE - counts via len() on a list comprehension
def:pub count_posts() -> int {
    return len([root -->][?:Post]);
}


# UPDATE - find by jid, mutate in place
def:pub publish(post_id: str) -> Post | None {
    for p in [root -->][?:Post] {
        if jid(p) == post_id {
            p.published = True;
            return p;
        }
    }
    return None;
}
