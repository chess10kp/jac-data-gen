"""Arilas/urbex#22 — bridge neighbor recursion with explicit visited guard."""

glob MAX_STEPS: int = 32;

node Chunk {
    has cx: int;
    has cy: int;
    has memo: str = "";
}

edge NeighborOf {}

obj ChunkGrid {
    has chunks: dict[str, Chunk] = {};

    def key(c: tuple[int, int]) -> str {
        return str(c[0]) + "," + str(c[1]);
    }

    def resolve(c: tuple[int, int]) -> Chunk | None {
        return self.chunks.get(self.key(c));
    }
}

walker BridgeWalk {
    has chain: list[tuple[int, int]] = [];
    has claimed: dict[str, bool] = {};
    has cycle_hit: bool = False;

    can step with Chunk entry {
        k = str(here.cx) + "," + str(here.cy);
        if k in self.claimed {
            self.cycle_hit = True;
            disengage;
        }
        if len(self.chain) >= MAX_STEPS { disengage; }
        if here.memo != "" { disengage; }
        self.claimed[k] = True;
        self.chain.append((here.cx, here.cy));
        nxt: Chunk | None = None;
        for n in [here ->:NeighborOf:->][?:Chunk] {
            if n.cy % 2 != 0 and len([n ->:NeighborOf:->][?:Chunk]) > 0 { continue; }
            nxt = n;
            break;
        }
        if nxt is not None { visit [nxt]; } else {
            here.memo = "x";
            disengage;
        }
    }
}

def load_chunks(
    coords: list[tuple[int, int]],
    neighbor_edges: list[tuple[tuple[int, int], tuple[int, int]]],
) -> ChunkGrid {
    g = ChunkGrid();
    for (cx, cy) in coords {
        nd = Chunk(cx=cx, cy=cy);
        root ++> nd;
        g.chunks[g.key((cx, cy))] = nd;
    }
    for (a, b) in neighbor_edges {
        na = g.resolve(a);
        nb = g.resolve(b);
        if na is not None and nb is not None { na +>:NeighborOf:+> nb; }
    }
    return g;
}

def bridge_chain(store: ChunkGrid, chunk: tuple[int, int]) -> list[tuple[int, int]] {
    nd = store.resolve(chunk);
    if nd is None { return []; }
    w = nd spawn BridgeWalk();
    return w.chain;
}

def hit_cycle(store: ChunkGrid, chunk: tuple[int, int]) -> bool {
    nd = store.resolve(chunk);
    if nd is None { return False; }
    w = nd spawn BridgeWalk();
    return w.cycle_hit;
}

test "linear bridge chain" {
    g = load_chunks(
        [(0, 0), (1, 0), (2, 0), (3, 1), (4, 0)],
        [
            ((0, 0), (1, 0)),
            ((1, 0), (2, 0)),
            ((2, 0), (3, 1)),
            ((3, 1), (4, 0)),
        ],
    );
    assert bridge_chain(g, (0, 0)) == [(0, 0), (1, 0), (2, 0)];
    assert hit_cycle(g, (0, 0)) == False;
}

test "cycle detected" {
    cyc = load_chunks([(0, 0), (2, 0)], [((0, 0), (2, 0)), ((2, 0), (0, 0))]);
    assert hit_cycle(cyc, (0, 0)) == True;
}
