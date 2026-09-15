"""INTENTIUS/chant#2417 — derive downstream fan-out order from the source graph."""

node Stack {
  has sid: str;
}

edge DependsOn {}

walker FanWalker {
  has claimed: dict[str, bool] = {};
  has touched: list[str] = [];
  has origin: str = "";

  can fan with Stack entry {
    if here.sid in self.claimed {
      skip;
    }
    self.claimed[here.sid] = True;
    if here.sid != self.origin {
      self.touched.append(here.sid);
    }
    print("fan " + here.sid);
    kids: list[Stack] = [];
    for ch in [here ->:DependsOn:->][?:Stack] {
      kids.append(ch);
    }
    kids = sort_stacks(kids);
    rev: list[Stack] = reverse_stacks(kids);
    for nd in rev {
      visit :0: [nd];
    }
  }
}

walker BootstrapWalker {
  has claimed: dict[str, bool] = {};
  has seen: list[str] = [];

  can launch with Stack entry {
    if here.sid in self.claimed {
      skip;
    }
    self.claimed[here.sid] = True;
    self.seen.append(here.sid);
    print("bootstrap " + here.sid);
    kids: list[Stack] = [];
    for ch in [here ->:DependsOn:->][?:Stack] {
      kids.append(ch);
    }
    kids = sort_stacks(kids);
    rev: list[Stack] = reverse_stacks(kids);
    for nd in rev {
      visit :0: [nd];
    }
  }
}

def sort_stacks(xs: list[Stack]) -> list[Stack] {
  out: list[Stack] = [];
  for nd in xs {
    out.append(nd);
  }
  for i in range(len(out)) {
    for j in range(i + 1, len(out)) {
      if out[j].sid < out[i].sid {
        tmp = out[i];
        out[i] = out[j];
        out[j] = tmp;
      }
    }
  }
  return out;
}

def reverse_stacks(xs: list[Stack]) -> list[Stack] {
  out: list[Stack] = [];
  for i in range(len(xs) - 1, -1, -1) {
    out.append(xs[i]);
  }
  return out;
}

def build_nodes(spec: dict[str, list[str]]) -> dict[str, Stack] {
  nodes: dict[str, Stack] = {};
  for sid in sorted(spec.keys()) {
    nd = Stack(sid=sid);
    root ++> nd;
    nodes[sid] = nd;
  }
  for sid in sorted(spec.keys()) {
    deps: list[str] = spec[sid];
    for dep in deps {
      if dep not in nodes {
        raise ValueError("UnknownDependencyError: " + dep);
      }
      nodes[dep] +>:DependsOn:+> nodes[sid];
    }
  }
  return nodes;
}

def indegrees(spec: dict[str, list[str]]) -> dict[str, int] {
  ids: list[str] = sorted(spec.keys());
  indeg: dict[str, int] = {};
  for sid in ids {
    indeg[sid] = 0;
  }
  for sid in ids {
    deps: list[str] = spec[sid];
    for dep in deps {
      if dep not in indeg {
        raise ValueError("UnknownDependencyError: " + dep);
      }
      indeg[sid] = indeg[sid] + 1;
    }
  }
  return indeg;
}

def resolve_order(spec: dict[str, list[str]]) -> list[str] {
  ids: list[str] = sorted(spec.keys());
  indeg: dict[str, int] = indegrees(spec);
  ready: list[str] = [];
  for sid in ids {
    if indeg[sid] == 0 {
      ready.append(sid);
    }
  }
  ready = sorted(ready);
  order: list[str] = [];
  while len(ready) > 0 {
    cur = ready[0];
    nxt_ready: list[str] = [];
    for i in range(1, len(ready)) {
      nxt_ready.append(ready[i]);
    }
    ready = nxt_ready;
    order.append(cur);
    for sid in ids {
      deps: list[str] = spec[sid];
      uses: bool = False;
      for dep in deps {
        if dep == cur {
          uses = True;
        }
      }
      if uses {
        indeg[sid] = indeg[sid] - 1;
        if indeg[sid] == 0 {
          ready.append(sid);
        }
      }
    }
    ready = sorted(ready);
  }
  if len(order) != len(ids) {
    raise ValueError("DependencyCycleError");
  }
  return order;
}

def resolve_waves(spec: dict[str, list[str]]) -> list[list[str]] {
  ids: list[str] = sorted(spec.keys());
  indeg: dict[str, int] = indegrees(spec);
  ready: list[str] = [];
  for sid in ids {
    if indeg[sid] == 0 {
      ready.append(sid);
    }
  }
  ready = sorted(ready);
  waves: list[list[str]] = [];
  seen: int = 0;
  while len(ready) > 0 {
    wave: list[str] = sorted(ready);
    waves.append(wave);
    seen = seen + len(wave);
    nxt_ready: list[str] = [];
    for cur in wave {
      for sid in ids {
        deps: list[str] = spec[sid];
        uses: bool = False;
        for dep in deps {
          if dep == cur {
            uses = True;
          }
        }
        if uses {
          indeg[sid] = indeg[sid] - 1;
          if indeg[sid] == 0 {
            nxt_ready.append(sid);
          }
        }
      }
    }
    ready = sorted(nxt_ready);
  }
  if seen != len(ids) {
    raise ValueError("DependencyCycleError");
  }
  return waves;
}

def subset_order(full: dict[str, list[str]], selected: list[str]) -> list[str] {
  order: list[str] = resolve_order(full);
  pick: dict[str, bool] = {};
  for sid in selected {
    pick[sid] = True;
  }
  out: list[str] = [];
  for sid in order {
    if sid in pick {
      out.append(sid);
    }
  }
  return out;
}

def cycle_members(spec: dict[str, list[str]]) -> list[str] | None {
  ids: list[str] = sorted(spec.keys());
  if len(ids) == 0 {
    return None;
  }
  for sid in ids {
    deps: list[str] = spec[sid];
    for dep in deps {
      if dep not in spec {
        return None;
      }
    }
  }
  indeg: dict[str, int] = indegrees(spec);
  ready: list[str] = [];
  for sid in ids {
    if indeg[sid] == 0 {
      ready.append(sid);
    }
  }
  ready = sorted(ready);
  seen: int = 0;
  while len(ready) > 0 {
    cur = ready[0];
    nxt_ready: list[str] = [];
    for i in range(1, len(ready)) {
      nxt_ready.append(ready[i]);
    }
    ready = nxt_ready;
    seen = seen + 1;
    for sid in ids {
      deps: list[str] = spec[sid];
      uses: bool = False;
      for dep in deps {
        if dep == cur {
          uses = True;
        }
      }
      if uses {
        indeg[sid] = indeg[sid] - 1;
        if indeg[sid] == 0 {
          ready.append(sid);
        }
      }
    }
    ready = sorted(ready);
  }
  if seen == len(ids) {
    return None;
  }
  cyc: list[str] = [];
  for sid in ids {
    if indeg[sid] > 0 {
      cyc.append(sid);
    }
  }
  return sorted(cyc);
}

def downstream_fan(changed: str, spec: dict[str, list[str]]) -> list[str] {
  if changed not in spec {
    raise ValueError("UnknownDependencyError: " + changed);
  }
  nodes: dict[str, Stack] = build_nodes(spec);
  w = nodes[changed] spawn FanWalker(claimed={}, touched=[], origin=changed);
  return w.touched;
}

def bootstrap_order(spec: dict[str, list[str]]) -> list[str] {
  nodes: dict[str, Stack] = build_nodes(spec);
  indeg: dict[str, int] = indegrees(spec);
  roots: list[Stack] = [];
  for sid in sorted(spec.keys()) {
    if indeg[sid] == 0 {
      roots.append(nodes[sid]);
    }
  }
  roots = sort_stacks(roots);
  rev: list[Stack] = reverse_stacks(roots);
  out: list[str] = [];
  picked: dict[str, bool] = {};
  for nd in rev {
    w = nd spawn BootstrapWalker(claimed={}, seen=[]);
    for sid in w.seen {
      if sid not in picked {
        picked[sid] = True;
        out.append(sid);
      }
    }
  }
  return out;
}

test "resolve_order_diamond" {
  spec: dict[str, list[str]] = {
    "a": [],
    "b": ["a"],
    "c": ["a"],
    "d": ["b", "c"],
  };
  assert resolve_order(spec) == ["a", "b", "c", "d"];
}

test "resolve_waves_diamond" {
  spec: dict[str, list[str]] = {
    "a": [],
    "b": ["a"],
    "c": ["a"],
    "d": ["b", "c"],
  };
  assert resolve_waves(spec) == [["a"], ["b", "c"], ["d"]];
}

test "subset_order_filters" {
  spec: dict[str, list[str]] = {
    "a": [],
    "b": ["a"],
    "c": ["a"],
    "d": ["b", "c"],
  };
  assert subset_order(spec, ["d", "a", "b"]) == ["a", "b", "d"];
}

test "cycle_members_detects" {
  spec: dict[str, list[str]] = {"x": ["y"], "y": ["x"]};
  assert cycle_members(spec) == ["x", "y"];
}

test "downstream_fan_from_source" {
  spec: dict[str, list[str]] = {
    "a": [],
    "b": ["a"],
    "c": ["a"],
    "d": ["b", "c"],
  };
  assert downstream_fan("a", spec) == ["b", "d", "c"];
}

test "bootstrap_order_matches_walk" {
  spec: dict[str, list[str]] = {
    "a": [],
    "b": ["a"],
    "c": ["a"],
    "d": ["b", "c"],
  };
  assert bootstrap_order(spec) == ["a", "b", "d", "c"];
}
