"""Comment-thread engagement aggregation.

Top-level posts hang off the root; replies connect upward through Reply
edges (reply -> parent). An aggregator walker descends into every reply,
and because exit abilities fire only after a comment's whole subtree has
been processed, each rollup folds its replies' finished totals plus its
own likes into one engagement number -- bottom-up summation without
explicit recursion. Top-level posts are then ranked with a lambda-key
sort.
"""

node Comment {
    has text: str;
    has likes: int = 0;
    has engagement_total: int = 0;  # own likes + all descendants
}

edge Reply: Comment --> Comment {}

walker ThreadAggregator {
    can start with Root entry {
        visit [-->];
    }

    can descend with Comment entry {
        visit [<-:Reply:<-];  # replies point at their parent
    }

    can rollup with Comment exit {
        total = here.likes;
        for reply in [<-:Reply:<-] {
            total += reply.engagement_total;
        }
        here.engagement_total = total;
    }
}

with entry {
    for stale in [root -->][?:Comment] {
        del stale;
    }

    post_hot = Comment(text="Walkers beat threads: discuss", likes=40);
    r1 = Comment(text="Strong agree, dispatch by arrival!", likes=12);
    r2 = Comment(text="Meh, callbacks forever.", likes=3);
    r1a = Comment(text="Found the 1998 developer", likes=25);
    r1b = Comment(text="arrival-based is the future", likes=7);
    post_cold = Comment(text="Why graphs? Explain like I'm five", likes=15);
    c1 = Comment(text="Because data has shape.", likes=18);
    c1a = Comment(text="This. So much this.", likes=9);

    root ++> [post_hot, post_cold];

    r1 +>: Reply() :+> post_hot;
    r2 +>: Reply() :+> post_hot;
    r1a +>: Reply() :+> r1;
    r1b +>: Reply() :+> r1;
    c1 +>: Reply() :+> post_cold;
    c1a +>: Reply() :+> c1;

    threads = [post_hot, post_cold];

    root spawn ThreadAggregator();

    # Rank the top-level posts by aggregated engagement.
    board: list[dict] = [];
    for t in threads {
        board.append({"text": t.text, "total": t.engagement_total});
    }
    board.sort(key=lambda (e: any) { e["total"]; }, reverse=True);

    print("Threads ranked by total engagement:");
    for e in board {
        print(f"  {e['total']:>3} points  \"{e['text']}\"");
    }
}
