# iss_algorithm003__algorithm__193
# Lift of algorithm003/algorithm#193 study notes:
#   210 Course Schedule II (DFS postorder topo sort, cycle -> []),
#   200 Number of Islands (flood fill closure count),
#   703 Kth Largest Element in a Stream (n < k edge case).

obj TopoRun {
    has order: list[int] = [];
    has cyc: bool = False;
}

node Course {
    has cid: int;
    has state: int = 0;
}

edge Pre {}

node Land {
    has key: int;
    has land: bool = True;
}

edge Adj {}

walker TopoWalker {
    has run: TopoRun;
    can step with Course entry {
        if self.run.cyc {
            skip;
        }
        if here.state != 0 {
            skip;
        }
        here.state = 1;
        nodes: list[Course] = [here];
        idxs: list[int] = [0];
        while len(nodes) > 0 {
            cur = nodes[len(nodes) - 1];
            i = idxs[len(idxs) - 1];
            kids: list[Course] = [];
            for x in [cur ->:Pre:->][?:Course] {
                kids.append(x);
            }
            if i >= len(kids) {
                self.run.order.append(cur.cid);
                cur.state = 2;
                nodes.pop();
                idxs.pop();
            } else {
                idxs[len(idxs) - 1] = i + 1;
                nb = kids[i];
                if nb.state == 1 {
                    self.run.cyc = True;
                } elif nb.state == 0 {
                    nb.state = 1;
                    nodes.append(nb);
                    idxs.append(0);
                }
            }
        }
        print("topo dfs finished from", here.cid, "cycle", self.run.cyc);
    }
}

walker Flood {
    has claimed: dict[int, bool] = {};
    can step with Land entry {
        if here.key in self.claimed {
            skip;
        }
        self.claimed[here.key] = True;
        visit [here ->:Adj:->] else {
            disengage;
        }
    }
}

# DFS postorder topological order; [] on cycle.
def find_order(num_courses: int, prereqs: list[list[int]]) -> list[int] {
    nodes_by_id: dict[int, Course] = {};
    for i in range(num_courses) {
        c = Course(cid=i);
        nodes_by_id[i] = c;
        root ++> c;
    }
    for p in prereqs {
        a = nodes_by_id[p[0]];
        b = nodes_by_id[p[1]];
        b +>:Pre:+> a;
    }
    run = TopoRun();
    for i in range(num_courses) {
        w = nodes_by_id[i] spawn TopoWalker(run=run);
    }
    if run.cyc {
        print("find_order: cycle detected, returning []");
        return [];
    }
    print("find_order:", run.order);
    return run.order;
}

# Count connected land components; unknown cells are water (tolerated).
def num_islands(grid: list[list[int]]) -> int {
    count: int = 0;
    claimed: dict[int, bool] = {};
    lands: dict[int, Land] = {};
    for r in range(len(grid)) {
        for c in range(len(grid[r])) {
            if grid[r][c] == 1 {
                nd = Land(key=r * 1000 + c);
                lands[r * 1000 + c] = nd;
                root ++> nd;
            }
        }
    }
    for r in range(len(grid)) {
        for c in range(len(grid[r])) {
            k = r * 1000 + c;
            if k in lands {
                if c + 1 < len(grid[r]) and (r * 1000 + c + 1) in lands {
                    a = lands[k];
                    b = lands[r * 1000 + c + 1];
                    a +>:Adj:+> b;
                }
                if r + 1 < len(grid) and ((r + 1) * 1000 + c) in lands {
                    a2 = lands[k];
                    b2 = lands[(r + 1) * 1000 + c];
                    a2 +>:Adj:+> b2;
                }
            }
        }
    }
    for k in sorted(lands.keys()) {
        if k in claimed {
            continue;
        }
        nd = lands[k];
        w = nd spawn Flood(claimed={});
        for kk in w.claimed.keys() {
            claimed[kk] = True;
        }
        count += 1;
        print("flood fill claimed", len(w.claimed), "cells");
    }
    print("num_islands:", count);
    return count;
}

# Streaming kth largest; returns -1 while fewer than k elements seen.
def kth_largest_add(k: int, init: list[int], stream: list[int]) -> list[int] {
    data: list[int] = [];
    for v in init {
        data.append(v);
    }
    res: list[int] = [];
    for v in stream {
        data.append(v);
        data = sorted(data);
        pos = len(data) - k;
        if pos < 0 {
            res.append(-1);
        } else {
            res.append(data[pos]);
        }
    }
    print("kth_largest_add:", res);
    return res;
}

test "topo_diamond_revisit" {
    res = find_order(4, [[0, 1], [0, 2], [1, 3], [2, 3]]);
    assert res == [3, 1, 2, 0];
}

test "topo_cycle_returns_empty" {
    res = find_order(3, [[1, 0], [2, 1], [0, 2]]);
    assert res == [];
}

test "topo_single_and_no_edge" {
    assert find_order(2, [[0, 1]]) == [1, 0];
    assert find_order(3, []) == [0, 1, 2];
}

test "islands_two_components" {
    grid = [[1, 0, 0, 1], [1, 0, 1, 0], [0, 0, 1, 0]];
    assert num_islands(grid) == 2;
}

test "islands_empty_and_water_only" {
    assert num_islands([]) == 0;
    assert num_islands([[0, 0], [0, 0]]) == 0;
}

test "kth_largest_stream_with_n_less_than_k" {
    assert kth_largest_add(3, [4, 5], [6, 2, 8]) == [4, 4, 5];
    assert kth_largest_add(1, [], [7]) == [7];
}
