"""OSP lift for ymcho2004/Grin#2 — graph BFS/DFS traversal."""

node Stock {
    has ticker: str;
    has vid: int = 0;
}

edge Link {
    has weight: float = 1.0;
}

obj GrinGraph {
    has hub: Stock;
    has by_ticker: dict[str, Stock] = {};
    has vid_next: int = 0;
}

walker BfsWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can bfs_step with Stock entry {
        if here.ticker in self.claimed { skip; }
        self.claimed[here.ticker] = True;
        self.order.append(here.ticker);
        print(here.ticker);
        nbrs: list[Stock] = [];
        for ch in [here ->:Link:->][?:Stock] {
            nbrs.append(ch);
        }
        nbrs = sort_stocks(nbrs);
        if nbrs {
            visit nbrs;
        }
    }
}

walker DfsWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can dfs_step with Stock entry {
        if here.ticker in self.claimed { skip; }
        self.claimed[here.ticker] = True;
        self.order.append(here.ticker);
        print(here.ticker);
        nbrs: list[Stock] = [];
        for ch in [here ->:Link:->][?:Stock] {
            nbrs.append(ch);
        }
        nbrs = sort_stocks(nbrs);
        if nbrs {
            k = len(nbrs) - 1;
            while k >= 0 {
                visit :0: [nbrs[k]];
                k -= 1;
            }
        }
    }
}

def sort_stocks(nodes: list[Stock]) -> list[Stock] {
    out: list[Stock] = [];
    for nd in nodes {
        out.append(nd);
    }
    i = 0;
    while i < len(out) {
        j = i + 1;
        while j < len(out) {
            if out[j].ticker < out[i].ticker {
                tmp = out[i];
                out[i] = out[j];
                out[j] = tmp;
            }
            j += 1;
        }
        i += 1;
    }
    return out;
}

def make_graph() -> GrinGraph {
    hub = Stock(ticker="__hub__", vid=-1);
    root ++> hub;
    return GrinGraph(hub=hub);
}

def add_vertex(g: GrinGraph, ticker: str) -> bool {
    if ticker in g.by_ticker { return False; }
    nd = Stock(ticker=ticker, vid=g.vid_next);
    g.vid_next += 1;
    g.hub ++> nd;
    g.by_ticker[ticker] = nd;
    return True;
}

def add_edge(g: GrinGraph, from_ticker: str, to_ticker: str, weight: float = 1.0) -> bool {
    if from_ticker not in g.by_ticker { return False; }
    if to_ticker not in g.by_ticker { return False; }
    src = g.by_ticker[from_ticker];
    dst = g.by_ticker[to_ticker];
    src +>: Link(weight=weight):+> dst;
    return True;
}

def bfs(g: GrinGraph, start_ticker: str) -> list[str] {
    if start_ticker not in g.by_ticker { return []; }
    start_nd = g.by_ticker[start_ticker];
    w = start_nd spawn BfsWalker(claimed={}, order=[]);
    return w.order;
}

def dfs(g: GrinGraph, start_ticker: str) -> list[str] {
    if start_ticker not in g.by_ticker { return []; }
    start_nd = g.by_ticker[start_ticker];
    w = start_nd spawn DfsWalker(claimed={}, order=[]);
    return w.order;
}
