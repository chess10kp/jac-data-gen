"""Publish posts onto the shared root, opened to readers with grant.

`root.shared` is the commons reachable from any request context; posts
stay owned and closed until grant(..., READ) opens them. On plain CLI
runs root.shared IS the current root -- the demo prints both jids.
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
        # Lands on the public graph whoever the caller is.
        fresh = root.shared +>: Posted() :+> Post(text=self.text, author=self.author);
        # Author opens this one post to every reader; ownership stays ours.
        grant(fresh, level=AccessLevel.READ);
        report {"published": jid(fresh)};
    }
}

with entry {
    print("root      :", jid(root));
    print("root.shared:", jid(root.shared));

    r1 = root spawn publish_post(text="OSP walkers are growing on me", author="jac");
    r2 = root spawn publish_post(text="grant is per-instance policy", author="sam");
    print(r1.reports, r2.reports);

    # Server usage:
    #   jac start ex_89_shared_publish.jac
    #   curl -X POST http://localhost:8000/walker/publish_post \
    #        -H "Content-Type: application/json" \
    #        -d '{"text": "hello feed", "author": "kim"}'
}
