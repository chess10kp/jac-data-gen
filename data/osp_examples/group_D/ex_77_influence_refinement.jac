"""Iterative influence-score refinement (simplified PageRank-style).

Alternating collect/distribute passes over Follows edges settle ranks;
the final leaderboard is sorted best-first with a lambda-key sort.
"""

node Account {
    has handle: str;
    has rank: float = 1.0;
    has incoming: float = 0.0;  # endorsement score for the next refresh
}

edge Follows: Account --> Account {}

walker CollectPass {
    can start with Root entry {
        visit [-->];
    }

    can refresh with Account entry {
        here.rank = 0.15 + 0.85 * here.incoming;
        here.incoming = 0.0;
    }
}

walker DistributePass {
    can start with Root entry {
        visit [-->];
    }

    can give with Account entry {
        following = [->:Follows:->];
        if len(following) == 0 {
            skip;  # sink account: its rank stays with itself
        }
        share = here.rank / len(following);
        for t in following {
            t.incoming += share;
        }
    }
}

with entry {
    for stale in [root -->][?:Account] {
        del stale;
    }

    news = Account(handle="@dailynews");
    deva = Account(handle="@deva");
    bot = Account(handle="@linkbot");
    prof = Account(handle="@prof_x");
    lurker = Account(handle="@lurker");

    root ++> [news, deva, bot, prof, lurker];

    deva +>: Follows() :+> news;
    prof +>: Follows() :+> news;
    bot +>: Follows() :+> news;
    bot +>: Follows() :+> prof;
    news +>: Follows() :+> prof;
    lurker +>: Follows() :+> deva;

    # Alternate collect/distribute passes until ranks stabilise.
    prev_top = "";
    for iteration in range(1, 26) {
        root spawn CollectPass();
        root spawn DistributePass();
        accounts = [root -->][?:Account];
        top_name = "";
        top_rank = -1.0;
        for a in accounts {
            if a.rank > top_rank {
                top_rank = a.rank;
                top_name = a.handle;
            }
        }
        if top_name == prev_top and iteration > 5 {
            print(f"Converged after {iteration} passes.");
            break;
        }
        prev_top = top_name;
    }

    # Final leaderboard, ranked by influence.
    accounts = [root -->][?:Account];
    board: list[dict] = [];
    for a in accounts {
        board.append({"handle": a.handle, "rank": a.rank});
    }
    board.sort(key=lambda (e: any) { e["rank"]; }, reverse=True);
    print("Influence leaderboard:");
    for i in range(len(board)) {
        h = board[i]["handle"];
        r = round(board[i]["rank"], 3);
        print(f"  {i + 1}. {h:<10} {r}");
    }
}
