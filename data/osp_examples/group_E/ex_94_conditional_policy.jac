"""Conditional archetype policy: READ when published, grants otherwise.

Returning AccessLevel | None ends the check immediately for published
reports while drafts fall through to stored grants -- closed until an
owner shares one, redundant once publishing flips the flag.
"""

node Report {
    has title: str = "";
    has body: str = "";
    has published: bool = False;

    def __jac_access__ -> AccessLevel | None {
        # Published: everyone reads, final answer.
        # Unpublished: fall through to stored grants (owner may share).
        return AccessLevel.READ if self.published else None;
    }
}

walker create_report {
    has title: str;
    has body: str;
    has publish_now: bool = False;

    can run with Root entry {
        r = here ++> Report(title=self.title, body=self.body, published=self.publish_now);
        # Drafts get no grant here: the hook returns None, no stored
        # grant exists, so they stay closed until selectively shared.
        report {"id": jid(r), "title": r.title};
    }
}

walker share_draft {
    has report_id: str;

    can run with Root entry {
        visit [-->];
    }

    can arm with Report entry {
        if jid(here) == self.report_id {
            # Selective share: None fell through to grants, so arming
            # one opens this draft (READ only) while others stay shut.
            grant(here, level=AccessLevel.READ);
            report {"shared": here.title};
            disengage;
        }
    }
}

walker publish_report {
    has report_id: str;

    can run with Root entry {
        visit [-->];
    }

    can flip with Report entry {
        if jid(here) == self.report_id {
            here.published = True;  # hook now returns READ for this node
            revoke(here);           # instance grant no longer needed
            report {"published": here.title};
            disengage;
        }
    }
}

walker list_reports {
    can run with Root entry {
        report [{"title": rp.title, "live": rp.published} for rp in [-->][?:Report]];
    }
}

with entry {
    root spawn create_report(title="Q3 numbers", body="up and to the right", publish_now=True);
    r2 = root spawn create_report(title="draft roadmap", body="half baked");
    rid = r2.reports[0]["id"];

    before = root spawn list_reports();
    print("before:", before.reports);

    shared = root spawn share_draft(report_id=rid);
    print("shared:", shared.reports);

    published = root spawn publish_report(report_id=rid);
    print("published:", published.reports);

    after = root spawn list_reports();
    print("after :", after.reports);
}
