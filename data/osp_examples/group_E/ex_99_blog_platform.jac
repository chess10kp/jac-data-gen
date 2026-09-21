"""Mini blog platform capstone: public feed, private drafts, cascade delete.

One file combining root.shared, grant/revoke, walker:pub endpoints,
walker:priv authoring tools, and cascade deletion of comments.

Server usage after `jac start ex_99_blog_platform.jac`:
    curl -X POST .../walker/publish -d '{"title": "hi", "body": "..."}'
"""

# ---------------------------------------------------------------- nodes

node Draft {
    has title: str;
    has body: str = "";
}

node Article {
    has title: str;
    has body: str = "";
}

node Comment {
    has text: str;
    has author: str = "anon";
}

edge Published { }   # shared root --> Article
edge Feedback { }    # Article --> Comment

# ------------------------------------------------- public reader surface

walker:pub publish {
    has title: str;
    has body: str;

    can run with Root entry {
        # Whoever calls lands this on the public graph.
        art = root.shared +>: Published() :+> Article(title=self.title, body=self.body);
        # Author opens it to every reader; ownership stays ours.
        grant(art, level=AccessLevel.READ);
        report {"published": jid(art), "url": f"/article/{jid(art)}"};
    }
}

walker:pub read_feed {
    has limit: int = 20;

    can run with Root entry {
        arts = [a for a in [root.shared ->:Published:->][?:Article]][-self.limit:];
        report [{"id": jid(a), "title": a.title,
                 "comments": len([a ->:Feedback:->])} for a in arts];
    }
}

walker:pub read_article {
    has article_id: str;

    can run with Root entry {
        for a in [root.shared ->:Published:->][?:Article] {
            if jid(a) == self.article_id {
                comments = [{"author": c.author, "text": c.text}
                            for c in [a ->:Feedback:->]];
                report {"title": a.title, "body": a.body, "comments": comments};
                disengage;
            }
        }
        report {"error": "no such article", "id": self.article_id};
    }
}

walker:pub leave_comment {
    has article_id: str;
    has text: str;
    has author: str = "anon";

    can run with Root entry {
        for a in [root.shared ->:Published:->][?:Article] {
            if jid(a) == self.article_id {
                c = a +>: Feedback() :+> Comment(author=self.author, text=self.text);
                grant(c, level=AccessLevel.READ);  # open our contribution
                report {"commented": jid(c)};
                disengage;
            }
        }
    }
}

# -------------------------------------------------- private author tools

walker:priv save_draft {
    has title: str;
    has body: str = "";

    can run with Root entry {
        d = here ++> Draft(title=self.title, body=self.body);
        report {"draft": jid(d)};
    }
}

walker:priv publish_draft {
    has draft_id: str;

    can find with Root entry {
        visit [-->];
    }

    can move with Draft entry {
        if jid(here) == self.draft_id {
            # Copy onto the shared graph, arm READ, retire the draft.
            art = root.shared +>: Published() :+> Article(title=here.title, body=here.body);
            grant(art, level=AccessLevel.READ);
            del here;
            report {"went_live": jid(art)};
            disengage;
        }
    }
}

# --------------------------------------------- moderation / cascade delete

walker:priv delete_article {
    has article_id: str;
    has doomed: list[any] = [];

    can find with Root entry {
        visit [root.shared ->:Published:->];  # moderators run on their own root
    }

    can gather with Article entry {
        if jid(here) == self.article_id {
            self.doomed.append(here);
            # Snapshot comments BEFORE deletion detaches the edges.
            for c in [here ->:Feedback:->] {
                self.doomed.append(c);
            }
            skip;
        }
    }

    can purge with Root exit {
        if not len(self.doomed) {
            skip;
        }
        removed = [jid(n) for n in self.doomed];
        for n in self.doomed {
            del n;  # each del also detaches its incident edges
        }
        revoke(self.doomed[0]);  # tidy any armed grant before the drop
        report {"deleted": removed};
    }
}

# ----------------------------------------------------------------- demo

with entry {
    live = root spawn publish(title="Why OSP", body="data has a shape");
    aid = live.reports[0]["published"];

    root spawn leave_comment(article_id=aid, text="convinced me", author="riley");

    d = root spawn save_draft(title="Unfinished thought", body="wip");
    root spawn publish_draft(draft_id=d.reports[0]["draft"]);

    feed = root spawn read_feed();
    print("feed:", feed.reports);

    full = root spawn read_article(article_id=aid);
    print("article:", full.reports);

    root spawn delete_article(article_id=aid);

    final_feed = root spawn read_feed();
    print("after delete:", final_feed.reports);
}
