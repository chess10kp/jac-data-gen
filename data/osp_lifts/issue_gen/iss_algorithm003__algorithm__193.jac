"""algorithm003/algorithm#193 — grid island DFS and course-order topo via post-order DFS."""

node Land {
    has r: int;
    has c: int;
}

edge LandAdj {}

node Course {
    has cid: int;
}

edge Prereq {}

walker IslandMarker {
    has claimed: dict[str, bool] = {};

    can paint with Land entry {
        key: str = "%d,%d" % (here.r, here.c);
        if key in self.claimed {
            skip;
        }
        self.claimed[key] = True;
        print({"paint": key});
        kids: list[Land] = [here ->:LandAdj:->][?:Land];
        for ch in kids {
            visit :0: ch;
        }
    }
}

walker IslandCounter {
    has claimed: dict[str, bool] = {};
    has total: int = 0;

    can count with Land entry {
        key: str = "%d,%d" % (here.r, here.c);
        if key in self.claimed {
            skip;
        }
        self.total += 1;
        print({"island": self.total});
        here spawn IslandMarker(claimed=self.claimed);
        visit here;
    }
}

walker TopoCollect {
    has claimed: dict[str, bool] = {};
    has order_stack: list[int] = [];

    can dfs with Course entry {
        cid_key: str = str(here.cid);
        if cid_key in self.claimed {
            skip;
        }
        self.claimed[cid_key] = True;
        deps: list[Course] = [here ->:Prereq:->][?:Course];
        for dep in deps {
            visit dep;
        }
        self.order_stack.append(here.cid);
        print({"postorder": here.cid});
    }
}

def _rc_key(r: int, c: int) -> str {
    return "%d,%d" % (r, c);
}

def _build_land_graph(grid: list[list[str]]) -> list[Land] {
    land_by_key: dict[str, Land] = {};
    seeds: list[Land] = [];
    rows: int = len(grid);
    if rows == 0 {
        return seeds;
    }
    cols: int = len(grid[0]);
    r: int = 0;
    while r < rows {
        c: int = 0;
        while c < cols {
            if grid[r][c] == "1" {
                key: str = _rc_key(r, c);
                nd: Land = Land(r=r, c=c);
                root ++> nd;
                land_by_key[key] = nd;
            }
            c += 1;
        }
        r += 1;
    }
    r = 0;
    while r < rows {
        c = 0;
        while c < cols {
            key = _rc_key(r, c);
            if key in land_by_key {
                here_nd: Land = land_by_key[key] as Land;
                if c + 1 < cols {
                    rk: str = _rc_key(r, c + 1);
                    if rk in land_by_key {
                        right_nd: Land = land_by_key[rk] as Land;
                        here_nd +>:LandAdj:+> right_nd;
                        right_nd +>:LandAdj:+> here_nd;
                    }
                }
                if r + 1 < rows {
                    dk: str = _rc_key(r + 1, c);
                    if dk in land_by_key {
                        down_nd: Land = land_by_key[dk] as Land;
                        here_nd +>:LandAdj:+> down_nd;
                        down_nd +>:LandAdj:+> here_nd;
                    }
                }
            }
            c += 1;
        }
        r += 1;
    }
    for k in sorted(land_by_key) {
        seeds.append(land_by_key[k] as Land);
    }
    return seeds;
}

def count_islands(grid: list[list[str]]) -> int {
    seeds: list[Land] = _build_land_graph(grid);
    if len(seeds) == 0 {
        return 0;
    }
    cw = (seeds[0]) spawn IslandCounter(claimed={});
    si: int = 0;
    while si < len(seeds) {
        visit seeds[si];
        si += 1;
    }
    return cw.total;
}

def _build_course_graph(num_courses: int, prerequisites: list[list[int]]) -> dict[str, Course] {
    by_id: dict[str, Course] = {};
    i: int = 0;
    while i < num_courses {
        cr: Course = Course(cid=i);
        root ++> cr;
        by_id[str(i)] = cr;
        i += 1;
    }
    for pair in prerequisites {
        a: int = pair[0];
        b: int = pair[1];
        if a < 0 or b < 0 or a >= num_courses or b >= num_courses {
            continue;
        }
        pre: Course = by_id[str(a)] as Course;
        post: Course = by_id[str(b)] as Course;
        pre +>:Prereq:+> post;
    }
    return by_id;
}

def course_order(num_courses: int, prerequisites: list[list[int]]) -> list[int] {
    if num_courses == 0 {
        return [];
    }
    by_id: dict[str, Course] = _build_course_graph(num_courses, prerequisites);
    anchor: Course = by_id["0"] as Course;
    tw = anchor spawn TopoCollect();
    ci: int = 0;
    while ci < num_courses {
        cur: Course = by_id[str(ci)] as Course;
        visit cur;
        ci += 1;
    }
    stack: list[int] = tw.order_stack;
    out: list[int] = [];
    j: int = len(stack) - 1;
    while j >= 0 {
        out.append(stack[j]);
        j -= 1;
    }
    return out;
}
