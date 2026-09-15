"""DAG traversal engine for task dependency validation.
rajat-wyrm/InternOps#1967
"""

node Task {
  has tid: str;
}

edge Requires {}

walker CycleScan {
  has claimed: dict[str, bool] = {};
  has stack: dict[str, bool] = {};
  has found: bool = False;
  has members: list[str] = [];

  can scan with Task entry {
    print({"cycle_scan": here.tid});
    if here.tid in self.stack {
      self.found = True;
      self.members.append(here.tid);
      skip;
    }
    if here.tid in self.claimed {
      skip;
    }
    self.claimed[here.tid] = True;
    self.stack[here.tid] = True;
    prereqs: list[Task] = [here ->:Requires:->][?:Task];
    for pr in prereqs {
      visit pr;
    }
    self.stack[here.tid] = False;
  }
}

walker DependentReach {
  has claimed: dict[str, bool] = {};
  has target: str = "";
  has hit: bool = False;

  can reach with Task entry {
    print({"dependent_reach": here.tid});
    if here.tid == self.target {
      self.hit = True;
      disengage;
    }
    if here.tid in self.claimed {
      skip;
    }
    self.claimed[here.tid] = True;
    dependents: list[Task] = [here <-:Requires:<-][?:Task];
    for dep in dependents {
      visit dep;
    }
  }
}

walker TopoWalk {
  has claimed: dict[str, bool] = {};
  has order: list[str] = [];

  can walk with Task entry {
    print({"topo_walk": here.tid});
    if here.tid in self.claimed {
      skip;
    }
    self.claimed[here.tid] = True;
    prereqs: list[Task] = [here ->:Requires:->][?:Task];
    for pr in prereqs {
      visit pr;
    }
    self.order.append(here.tid);
  }
}

def _build_tasks(spec: dict[str, list[str]]) -> dict[str, Task] {
  nodes: dict[str, Task] = {};
  ids: list[str] = sorted(spec);
  for tid in ids {
    t = Task(tid=tid);
    root ++> t;
    nodes[tid] = t;
  }
  for tid in ids {
    reqs: list[str] = spec[tid];
    if reqs is None {
      reqs = [];
    }
    for rid in reqs {
      if rid in nodes {
        nodes[tid] +>:Requires:+> nodes[rid];
      }
    }
  }
  return nodes;
}

def has_cycle(spec: dict[str, list[str]]) -> bool {
  nodes: dict[str, Task] = _build_tasks(spec);
  keys: list[str] = sorted(nodes);
  for k in keys {
    w = nodes[k] spawn CycleScan(
      claimed={},
      stack={},
      found=False,
      members=[]
    );
    print({"has_cycle_probe": k, "found": w.found});
    if w.found {
      return True;
    }
  }
  return False;
}

def find_cycle_nodes(spec: dict[str, list[str]]) -> list[str] {
  nodes: dict[str, Task] = _build_tasks(spec);
  out: list[str] = [];
  keys: list[str] = sorted(nodes);
  for k in keys {
    w = nodes[k] spawn CycleScan(
      claimed={},
      stack={},
      found=False,
      members=[]
    );
    if w.found {
      out = sorted(w.members);
      print({"cycle_nodes": out});
      return out;
    }
  }
  return out;
}

def topological_order(spec: dict[str, list[str]]) -> list[str] {
  empty: list[str] = [];
  if has_cycle(spec) {
    print({"topo_blocked": True});
    return empty;
  }
  nodes: dict[str, Task] = _build_tasks(spec);
  shared_claimed: dict[str, bool] = {};
  shared_order: list[str] = [];
  keys: list[str] = sorted(nodes);
  for k in keys {
    w = nodes[k] spawn TopoWalk(claimed=shared_claimed, order=shared_order);
    print({"topo_from": k, "size": len(w.order)});
  }
  return shared_order;
}

def would_create_cycle(
  spec: dict[str, list[str]],
  task_id: str,
  prereq_id: str
) -> bool {
  if task_id not in spec and task_id not in _build_tasks(spec) {
    # unknown task id — tolerate, do not block
    print({"unknown_task": task_id});
    return False;
  }
  nodes: dict[str, Task] = _build_tasks(spec);
  if task_id not in nodes {
    print({"unknown_task": task_id});
    return False;
  }
  if prereq_id not in nodes {
    print({"unknown_prereq": prereq_id});
    return False;
  }
  if task_id == prereq_id {
    print({"self_loop": True});
    return True;
  }
  w = nodes[prereq_id] spawn DependentReach(
    claimed={},
    target=task_id,
    hit=False
  );
  print({"would_cycle": w.hit});
  return w.hit;
}

test "has_cycle_acyclic" {
  spec: dict[str, list[str]] = {"a": [], "b": ["a"], "c": ["b"]};
  assert (has_cycle(spec) == False);
}

test "has_cycle_cyclic" {
  spec: dict[str, list[str]] = {"a": ["b"], "b": ["a"]};
  assert (has_cycle(spec) == True);
}

test "topological_order_acyclic" {
  spec: dict[str, list[str]] = {"a": [], "b": ["a"], "c": ["b"]};
  order: list[str] = topological_order(spec);
  assert (order == ["a", "b", "c"]);
}

test "topological_order_blocked_on_cycle" {
  spec: dict[str, list[str]] = {"a": ["b"], "b": ["a"]};
  order: list[str] = topological_order(spec);
  assert (order == []);
}

test "would_create_self_loop" {
  spec: dict[str, list[str]] = {"a": []};
  assert (would_create_cycle(spec, "a", "a") == True);
}

test "would_create_unknown_task" {
  spec: dict[str, list[str]] = {"a": []};
  assert (would_create_cycle(spec, "z", "a") == False);
}
