"""Read the public feed off the shared root.

This is the reader half of my micro-blog. Any caller -- even anonymous
-- can walk the shared root's children because the shared root's access
level floors at CONNECT, so listing posts needs no auth at all. Only
posts whose authors armed a READ grant show real content to other users;
on a single-user CLI run everything is visible since root.shared is just
root.
"""

node Post {
    has text: str;
    has author: str;
}

edge Posted { }

walker:pub publish_post {
    has text: str;
    has author: str = "anon";

    can run with Root entry {
        fresh = root.shared +>: Posted() :+> Post(text=self.text, author=self.author);
        grant(fresh, level=AccessLevel.READ);
    }
}

walker:pub read_feed {
    can run with Root entry {
        # Traversal from the shared commons; order follows creation order.
        posts = [p for p in [root.shared ->:Posted:->][?:Post]];
        report [{"author": p.author, "text": p.text} for p in posts];
    }
}

with entry {
    root spawn publish_post(text="first!", author="ada");
    root spawn publish_post(text="second post", author="ben");
    root spawn publish_post(text="a quiet third", author="cy");

    result = root spawn read_feed();
    print(result.reports);
}
