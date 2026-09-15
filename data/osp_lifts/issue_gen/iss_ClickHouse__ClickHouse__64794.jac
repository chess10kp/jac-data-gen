"""ClickHouse/ClickHouse#64794 — recursive task descent (WITH RECURSIVE rtq)."""

node Task {
    has task_id: int;
    has name: str;
    has parent_id: int;
}

edge HasChild {}

node TaskGraph {
    has by_id: dict[int, Task] = {};
}

walker RecursiveCteWalker {
    has anchor: int = 0;
    has claimed: dict[int, bool] = {};
    has found: list[int] = [];

    can boot with entry {
        seeds: list[Task] = [];
        for nd in [root ->] {
            t = nd as Task;
            if t.parent_id == self.anchor {
                seeds.append(t);
            }
        }
        if len(seeds) > 0 {
            visit :0: seeds;
        } else {
            disengage;
        }
    }

    can grow with Task entry {
        if here.task_id in self.claimed {
            skip;
        }
        in_base = here.parent_id == self.anchor;
        in_recur = here.parent_id in self.claimed;
        if not in_base and not in_recur {
            skip;
        }
        self.claimed[here.task_id] = True;
        self.found.append(here.task_id);
        print(here.task_id);
        kids: list[Task] = [];
        for ch in [here ->:HasChild:->][?:Task] {
            kids.append(ch);
        }
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def build_task_graph(rows: list[dict]) -> TaskGraph {
    g = TaskGraph();
    g.by_id = {};
    for row in rows {
        tid = row["task_id"] as int;
        nm = row["name"] as str;
        pid = row["parent_id"] as int;
        t = Task(task_id=tid, name=nm, parent_id=pid);
        g.by_id[tid] = t;
        root ++> t;
    }
    for tid, t in g.by_id {
        pid = t.parent_id;
        if pid in g.by_id {
            par = g.by_id[pid] as Task;
            par +>:HasChild:+> t;
        }
    }
    return g;
}

def recursive_closure_ids(g: TaskGraph, anchor_parent_id: int) -> list[int] {
    wk = root spawn RecursiveCteWalker(
        anchor=anchor_parent_id,
        claimed={},
        found=[]
    );
    return sorted(wk.found);
}

def count_recursive_closure(g: TaskGraph, anchor_parent_id: int) -> int {
    ids = recursive_closure_ids(g, anchor_parent_id);
    return len(ids);
}

with entry {
    demo: list[dict] = [];
    demo.append({"task_id": 101, "name": "root_child", "parent_id": 77438101});
    demo.append({"task_id": 102, "name": "grand", "parent_id": 101});
    g = build_task_graph(demo);
    wk = root spawn RecursiveCteWalker(anchor=77438101, claimed={}, found=[]);
    print(count_recursive_closure(g, 77438101));
}
