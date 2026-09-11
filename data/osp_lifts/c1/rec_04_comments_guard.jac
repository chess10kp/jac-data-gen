"""Comment thread lineage lifted to OSP.

Comments are ``Comment`` nodes; ``ReplyTo`` edges point from a reply
to its parent comment. Thread paths climb with a linear walker;
reply volume folds bottom-up in exit abilities.
"""

node Comment {
    has cid: str;            # unique comment handle
    has author: str;
    has body: str;
    has reply_total: int = 0;    # staging: replies below, folded at exit
    has deep: int = 0;           # staging: longest reply chain, folded at exit
}

edge ReplyTo: Comment --> Comment {}

"""Build the fixture thread deterministically; returns the OP."""
def build_thread() -> Comment {
    root ++> (op := Comment(cid="c1", author="ana", body="launch day!"));
    root ++> (r1 := Comment(cid="c2", author="bo", body="congrats"));
    root ++> (r2 := Comment(cid="c3", author="cy", body="how does auth work?"));
    root ++> (r11 := Comment(cid="c4", author="ana", body="thanks!"));
    root ++> (r21 := Comment(cid="c5", author="dee", body="JWTs"));
    root ++> (r211 := Comment(cid="c6", author="bo", body="any rotation?"));
    r1 +>:ReplyTo:+> op;
    r2 +>:ReplyTo:+> op;
    r11 +>:ReplyTo:+> r1;
    r21 +>:ReplyTo:+> r2;
    r211 +>:ReplyTo:+> r21;
    return op;
}

"""Create a reply under `parent` (None for an OP) and return it."""
def post(parent: Comment | None, author: str, body: str) -> Comment {
    # Every comment hangs off root at creation, so the count yields a fresh cid.
    next_id = "c" + str(len([root -->]) + 1);
    root ++> (c := Comment(cid=next_id, author=author, body=body));
    if parent is not None {
        c +>:ReplyTo:+> parent;
    }
    return c;
}

walker ThreadClimb {
    """Climbs ReplyTo edges to the OP; linear, so list state is safe."""
    has authors: list[str] = [];
    has claimed: dict[str, bool] = {};

    can climb with Comment entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.authors.append(here.author);
        visit [->:ReplyTo:->] else { report self.authors; disengage; }
    }
}

walker ReplyFold {
    """Exit folds reply counts and chain depths bottom-up."""
    has claimed: dict[str, bool] = {};

    can descend with Comment entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        visit [<-:ReplyTo:<-];
    }

    can fold with Comment exit {
        total = 0;
        best = 0;
        for r in [<-:ReplyTo:<-] {
            total += 1 + r.reply_total;
            if r.deep > best {
                best = r.deep;
            }
        }
        here.reply_total = total;
        here.deep = 1 + best;
    }
}

"""Authors from the OP down to `start`, inclusive; OP first."""
def thread_path(start: Comment) -> list[str] {
    w = start spawn ThreadClimb();
    return w.authors[::-1];
}

"""Number of replies at or below `start`, excluding `start` itself."""
def reply_count(start: Comment) -> int {
    start spawn ReplyFold();
    return start.reply_total;
}

"""Author of the thread-starting comment above `start`."""
def op_author(start: Comment) -> str {
    w = start spawn ThreadClimb();
    return w.authors[-1];
}

"""Length of the longest reply chain below `start`, counting `start`."""
def deepest_reply(start: Comment) -> int {
    start spawn ReplyFold();
    return start.deep;
}
test "thread_path climbs OP-first" {
    op = build_thread();
    kids = [op <--][?:Comment];
    r2 = [k for k in kids if k.author == "cy"][0];
    r21 = [k for k in [r2 <--][?:Comment]][0];
    r211 = [k for k in [r21 <--][?:Comment]][0];
    assert thread_path(r211) == ["ana", "cy", "dee", "bo"];
    assert thread_path(op) == ["ana"];
}

test "reply_count folds replies below" {
    op = build_thread();
    assert reply_count(op) == 5;
}

test "op_author reaches the OP" {
    op = build_thread();
    r2 = [k for k in [op <--][?:Comment] if k.author == "cy"][0];
    r211 = [k for k in [[r2 <--][?:Comment][0] <--][?:Comment]][0];
    assert op_author(r211) == "ana";
}

test "deepest_reply folds longest chain" {
    op = build_thread();
    assert deepest_reply(op) == 4;
}
test "post extends the thread" {
    op = build_thread();
    kids = [op <--][?:Comment];
    r2 = [k for k in kids if k.author == "cy"][0];
    r21 = [k for k in [r2 <--][?:Comment]][0];
    late = post(r21, "eli", "yes, rotate");
    assert thread_path(late) == ["ana", "cy", "dee", "eli"];
    assert reply_count(op) == 6;
    assert op_author(late) == "ana";
    assert deepest_reply(late) == 1;
    fresh_op = post(None, "zoe", "new thread");
    assert thread_path(fresh_op) == ["zoe"];
}
